// bluetooth_service.dart
// Handles all Bluetooth Low Energy operations:
//  - Scanning for devices
//  - Connecting to the ESP32 patch device
//  - Receiving continuous data notifications
//  - Exposing a stream of parsed PatchData

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'data_parser.dart';

/// UUIDs for the ESP32 CPR patch BLE service and characteristic.
/// Replace these with the actual UUIDs programmed on your device.
const String kServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String kCharacteristicUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

/// Connection states for the UI to react to.
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// BluetoothService manages the full BLE lifecycle and exposes streams.
class BluetoothService extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  String _statusMessage = 'Not connected';
  BluetoothDevice? _connectedDevice;
  PatchData? _latestData;

  // Keeps a short history for the heart-rate graph (max 60 points)
  final List<PatchData> _dataHistory = [];
  static const int _maxHistory = 60;

  // Internal subscriptions we need to cancel on disconnect
  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;

  // Discovered devices during scan
  final List<BluetoothDevice> _foundDevices = [];

  // ── Getters ───────────────────────────────────────────────────────────
  BleConnectionState get connectionState => _connectionState;
  String get statusMessage => _statusMessage;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  PatchData? get latestData => _latestData;
  List<PatchData> get dataHistory => List.unmodifiable(_dataHistory);
  List<BluetoothDevice> get foundDevices => List.unmodifiable(_foundDevices);
  bool get isConnected => _connectionState == BleConnectionState.connected;

  // ── Demo / Simulation ─────────────────────────────────────────────────
  // Timer used when running the built-in demo simulation
  Timer? _demoTimer;
  int _demoStep = 0;

  /// Starts a simulated data feed so the app works without real hardware.
  void startDemoMode() {
    _setStatus(BleConnectionState.connected, 'Demo mode active');
    _demoTimer?.cancel();
    _demoStep = 0;

    // Cycle through a realistic sequence of readings
    const demoSequence = [
      'HR:72,STATUS:NORMAL,CPR:OFF,ALERT:NO',
      'HR:74,STATUS:NORMAL,CPR:OFF,ALERT:NO',
      'HR:76,STATUS:NORMAL,CPR:OFF,ALERT:NO',
      'HR:80,STATUS:NORMAL,CPR:OFF,ALERT:NO',
      'HR:95,STATUS:ABNORMAL,CPR:OFF,ALERT:NO',
      'HR:110,STATUS:ABNORMAL,CPR:OFF,ALERT:YES',
      'HR:130,STATUS:ARREST,CPR:ON,ALERT:YES',
      'HR:0,STATUS:ARREST,CPR:ON,ALERT:YES',
      'HR:0,STATUS:ARREST,CPR:ON,ALERT:YES',
      'HR:45,STATUS:ARREST,CPR:ON,ALERT:YES',
      'HR:58,STATUS:ABNORMAL,CPR:OFF,ALERT:YES',
      'HR:65,STATUS:NORMAL,CPR:OFF,ALERT:NO',
      'HR:70,STATUS:NORMAL,CPR:OFF,ALERT:NO',
    ];

    _demoTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      final raw = demoSequence[_demoStep % demoSequence.length];
      _processRaw(raw);
      _demoStep++;
    });
    notifyListeners();
  }

  /// Stops demo simulation.
  void stopDemoMode() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _setStatus(BleConnectionState.disconnected, 'Demo stopped');
  }

  // ── BLE Scanning ──────────────────────────────────────────────────────

  /// Start scanning for nearby BLE devices.
  Future<void> startScan() async {
    if (_connectionState == BleConnectionState.scanning) return;

    _foundDevices.clear();
    _setStatus(BleConnectionState.scanning, 'Scanning for devices…');

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (!_foundDevices.contains(r.device)) {
            _foundDevices.add(r.device);
            notifyListeners();
          }
        }
      });

      // After timeout, revert to idle if not connected
      await Future.delayed(const Duration(seconds: 10));
      if (_connectionState == BleConnectionState.scanning) {
        _setStatus(BleConnectionState.disconnected, 'Scan complete');
      }
    } catch (e) {
      _setStatus(BleConnectionState.error, 'Scan failed: $e');
    }
  }

  /// Stop an active scan.
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    if (_connectionState == BleConnectionState.scanning) {
      _setStatus(BleConnectionState.disconnected, 'Scan stopped');
    }
  }

  // ── BLE Connection ────────────────────────────────────────────────────

  /// Connect to a specific BLE device and subscribe to notifications.
  Future<void> connectTo(BluetoothDevice device) async {
    _setStatus(BleConnectionState.connecting, 'Connecting to ${device.platformName}…');
    await stopScan();

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Discover services
      final services = await device.discoverServices();
      bool found = false;

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == kServiceUUID.toLowerCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == kCharacteristicUUID.toLowerCase()) {
              // Subscribe to notifications
              await char.setNotifyValue(true);
              _dataSubscription = char.lastValueStream.listen((value) {
                final raw = utf8.decode(value);
                _processRaw(raw);
              });
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }

      if (found) {
        _setStatus(BleConnectionState.connected,
            'Connected to ${device.platformName}');
      } else {
        _setStatus(BleConnectionState.error,
            'CPR service not found on device');
        await device.disconnect();
      }
    } catch (e) {
      _setStatus(BleConnectionState.error, 'Connection failed: $e');
    }
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    _dataSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _connectedDevice = null;
    _dataSubscription?.cancel();
    _setStatus(BleConnectionState.disconnected, 'Device disconnected');
  }

  // ── Data Processing ───────────────────────────────────────────────────

  void _processRaw(String raw) {
    final data = PatchData.fromRaw(raw);
    if (data == null) return; // Ignore malformed frames

    _latestData = data;

    // Keep rolling history for the graph
    _dataHistory.add(data);
    if (_dataHistory.length > _maxHistory) {
      _dataHistory.removeAt(0);
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _setStatus(BleConnectionState state, String message) {
    _connectionState = state;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }
}
