// bluetooth_screen.dart — Enhanced
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bluetooth_service.dart';
import '../app_theme.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BluetoothService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONNECTIVITY',
                        style: TextStyle(
                          fontSize: 10, letterSpacing: 3,
                          color: AppTheme.cyan, fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: 3),
                    Text('Device Manager',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        )),
                  ],
                ),
              ),

              _StatusCard(ble: ble),
              const SizedBox(height: 16),
              _ActionBar(ble: ble),
              const SizedBox(height: 20),

              if (ble.foundDevices.isNotEmpty) ...[
                const Text('DISCOVERED DEVICES',
                    style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: ble.foundDevices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _DeviceTile(
                      device: ble.foundDevices[i],
                      onTap: () => ble.connectTo(ble.foundDevices[i]),
                    ),
                  ),
                ),
              ] else
                Expanded(child: _EmptyState(ble: ble)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final BluetoothService ble;
  const _StatusCard({required this.ble});

  Color get _color {
    switch (ble.connectionState) {
      case BleConnectionState.connected: return AppTheme.green;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting: return AppTheme.yellow;
      case BleConnectionState.error: return AppTheme.red;
      default: return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanning = ble.connectionState == BleConnectionState.scanning ||
        ble.connectionState == BleConnectionState.connecting;

    return Container(
      decoration: AppTheme.glassCard(borderColor: _color, borderOpacity: 0.3),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.1),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.bluetooth, color: _color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ble.connectionState.name.toUpperCase(),
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 3),
                Text(ble.statusMessage,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (scanning)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _color),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final BluetoothService ble;
  const _ActionBar({required this.ble});

  @override
  Widget build(BuildContext context) {
    final scanning = ble.connectionState == BleConnectionState.scanning;
    final connected = ble.isConnected;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: scanning ? 'STOP SCAN' : 'SCAN',
                icon: scanning ? Icons.stop_circle_outlined : Icons.radar,
                color: AppTheme.cyan,
                onTap: () => scanning ? ble.stopScan() : ble.startScan(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                label: 'DISCONNECT',
                icon: Icons.link_off,
                color: AppTheme.red,
                onTap: connected ? ble.disconnect : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Demo button — full width with gradient
        GestureDetector(
          onTap: () => connected ? ble.stopDemoMode() : ble.startDemoMode(),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: connected ? AppTheme.redGrad : AppTheme.cyanGrad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (connected ? AppTheme.red : AppTheme.cyan)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  connected ? Icons.stop : Icons.play_circle_outline,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  connected ? 'STOP DEMO MODE' : '▶  START DEMO MODE',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.4) : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: enabled ? color : AppTheme.textTertiary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: enabled ? color : AppTheme.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                )),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final dynamic device;
  final VoidCallback onTap;
  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
    final id = device.remoteId.str;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCard(borderColor: AppTheme.cyan, borderOpacity: 0.2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyan.withValues(alpha: 0.08),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.bluetooth, color: AppTheme.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(id,
                      style: const TextStyle(
                          color: AppTheme.textTertiary, fontSize: 10,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
              ),
              child: const Text('CONNECT',
                  style: TextStyle(
                      color: AppTheme.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BluetoothService ble;
  const _EmptyState({required this.ble});

  @override
  Widget build(BuildContext context) {
    final scanning = ble.connectionState == BleConnectionState.scanning;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 56,
            color: scanning ? AppTheme.cyan : AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            scanning ? 'Scanning for devices...' : 'No devices found',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            scanning ? 'Ensure patch device is powered on' : 'Tap SCAN or use Demo Mode',
            style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
