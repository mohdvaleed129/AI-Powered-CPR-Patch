// data_parser.dart
// Parses raw BLE strings like "HR:78,STATUS:NORMAL,CPR:OFF,ALERT:NO"
// into a strongly-typed PatchData model.

/// Possible cardiac status values from the patch device.
enum CardiacStatus { normal, abnormal, arrest, unknown }

/// Represents one data frame received from the CPR patch device.
class PatchData {
  final int heartRate;
  final CardiacStatus status;
  final bool cprActive;
  final bool alertSent;
  final DateTime timestamp;

  const PatchData({
    required this.heartRate,
    required this.status,
    required this.cprActive,
    required this.alertSent,
    required this.timestamp,
  });

  /// Factory: parse raw BLE string. Returns null on any parse error.
  static PatchData? fromRaw(String raw) {
    try {
      // Split into key:value pairs
      final parts = raw.trim().split(',');
      if (parts.length < 4) return null;

      final map = <String, String>{};
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          map[kv[0].trim().toUpperCase()] = kv[1].trim().toUpperCase();
        }
      }

      // Parse heart rate
      final hr = int.tryParse(map['HR'] ?? '') ?? 0;

      // Parse status
      CardiacStatus status;
      switch (map['STATUS']) {
        case 'NORMAL':
          status = CardiacStatus.normal;
          break;
        case 'ABNORMAL':
          status = CardiacStatus.abnormal;
          break;
        case 'ARREST':
          status = CardiacStatus.arrest;
          break;
        default:
          status = CardiacStatus.unknown;
      }

      final cpr = map['CPR'] == 'ON';
      final alert = map['ALERT'] == 'YES';

      return PatchData(
        heartRate: hr,
        status: status,
        cprActive: cpr,
        alertSent: alert,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null; // Silently handle malformed data
    }
  }

  /// Returns a human-readable status label.
  String get statusLabel {
    switch (status) {
      case CardiacStatus.normal:
        return 'NORMAL';
      case CardiacStatus.abnormal:
        return 'ABNORMAL';
      case CardiacStatus.arrest:
        return 'ARREST';
      case CardiacStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// Simulated AI confidence score (0–100) based on HR + status.
  int get aiConfidence {
    switch (status) {
      case CardiacStatus.arrest:
        return 97;
      case CardiacStatus.abnormal:
        return 75;
      case CardiacStatus.normal:
        return 20;
      case CardiacStatus.unknown:
        return 0;
    }
  }
}

/// Parses a list of CSV rows into PatchData objects (for Dataset screen).
class CsvParser {
  static List<PatchData> fromCsvRows(List<List<dynamic>> rows) {
    final result = <PatchData>[];
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      try {
        CardiacStatus status;
        switch (row[2].toString().toUpperCase()) {
          case 'NORMAL':
            status = CardiacStatus.normal;
            break;
          case 'ABNORMAL':
            status = CardiacStatus.abnormal;
            break;
          case 'ARREST':
            status = CardiacStatus.arrest;
            break;
          default:
            status = CardiacStatus.unknown;
        }
        result.add(PatchData(
          heartRate: int.tryParse(row[1].toString()) ?? 0,
          status: status,
          cprActive: row[3].toString().toUpperCase() == 'ON',
          alertSent: row[4].toString().toUpperCase() == 'YES',
          timestamp: DateTime.tryParse(row[0].toString()) ?? DateTime.now(),
        ));
      } catch (_) {
        continue;
      }
    }
    return result;
  }
}
