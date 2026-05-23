import 'package:flutter/foundation.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Syncs Health Connect data (exercise, heart rate, sleep) to the backend.
/// Uses SharedPreferences to track last-synced timestamps per data type,
/// so only genuinely new records are submitted on each sync call.
class HealthConnectSyncService {
  final CurrentDiaryNotifier diaryNotifier;

  HealthConnectSyncService({required this.diaryNotifier});

  static const _types = [
    HealthConnectDataType.ExerciseSession,
    HealthConnectDataType.HeartRate,
    HealthConnectDataType.SleepSession,
  ];

  // SharedPreferences keys for the last-synced timestamp per type
  static const _keyLastSyncExercise = 'hc_last_sync_exercise';
  static const _keyLastSyncHeartRate = 'hc_last_sync_heart_rate';
  static const _keyLastSyncSleep = 'hc_last_sync_sleep';

  /// Returns true if Health Connect is available AND permissions are granted.
  Future<bool> _isReady() async {
    try {
      final available = await HealthConnectFactory.isAvailable();
      if (!available) return false;
      final granted =
          await HealthConnectFactory.hasPermissions(_types, readOnly: true);
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Main entry-point: sync all three data types silently.
  Future<void> syncAll() async {
    if (!await _isReady()) {
      debugPrint('[HC Sync] Not ready (HC unavailable or no permissions)');
      return;
    }
    debugPrint('[HC Sync] Starting Health Connect sync...');
    await Future.wait([
      _syncExercise(),
      _syncHeartRate(),
      _syncSleep(),
    ]);
    debugPrint('[HC Sync] Done.');
  }

  // ── Exercise ────────────────────────────────────────────────────────────────

  Future<void> _syncExercise() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      // Only fetch records newer than the last successful sync.
      // Fall back to start-of-today if never synced before.
      final lastSyncMs = prefs.getInt(_keyLastSyncExercise);
      final start = lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs, isUtc: true)
          : DateTime.utc(now.year, now.month, now.day);

      debugPrint('[HC Sync] Exercise: fetching from $start');

      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.ExerciseSession,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? [];
      if (records.isEmpty) {
        debugPrint('[HC Sync] Exercise: no new records since $start');
        return;
      }

      for (final raw in records) {
        if (raw is! Map) continue;

        final name = _exerciseName(raw);
        final startDt = _parseIso(raw['startTime']);
        final endDt = _parseIso(raw['endTime']);

        if (startDt == null || endDt == null) continue;

        final durationMinutes =
            endDt.difference(startDt).inMinutes.clamp(1, 999999);

        // Heart rate samples inside the exercise session (best-effort)
        final avgBpm = _avgBpmFromRecord(raw);

        final payload = <String, dynamic>{
          'name': name,
          'activityCategory': 'Rekreasi/Olahraga',
          // Health Connect doesn't expose a direct intensity level;
          // default to 'sedang' as a safe middle ground.
          'intensityLevel': 'sedang',
          'startTime': _toHHmm(startDt),
          'endTime': _toHHmm(endDt),
          'duration': durationMinutes,
          // "Durasi di luar ruangan" = same as activity duration per requirement
          'outdoorMinutes': durationMinutes,
          if (avgBpm != null) 'heartRate': avgBpm,
          'note': 'Disinkronkan dari Health Connect',
        };

        try {
          await diaryNotifier.addActivitiesFromModal(payload);
          debugPrint('[HC Sync] Exercise saved: $name ($durationMinutes min)');
        } catch (e) {
          debugPrint('[HC Sync] Exercise save failed ($name): $e');
        }
      }

      // Mark sync time AFTER successfully processing all records
      await prefs.setInt(_keyLastSyncExercise, now.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[HC Sync] _syncExercise error: $e');
    }
  }

  // ── Heart Rate ───────────────────────────────────────────────────────────────

  Future<void> _syncHeartRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      final lastSyncMs = prefs.getInt(_keyLastSyncHeartRate);
      final start = lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs, isUtc: true)
          : DateTime.utc(now.year, now.month, now.day);

      debugPrint('[HC Sync] Heart rate: fetching from $start');

      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.HeartRate,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? [];
      final bpmValues = <num>[];

      for (final record in records) {
        if (record is! Map) continue;

        final direct = _toNum(record['beatsPerMinute'] ?? record['bpm']);
        if (direct != null) bpmValues.add(direct);

        final samples = record['samples'];
        if (samples is List) {
          for (final s in samples) {
            if (s is! Map) continue;
            final v = _toNum(s['beatsPerMinute'] ?? s['bpm'] ?? s['value']);
            if (v != null) bpmValues.add(v);
          }
        }
      }

      if (bpmValues.isEmpty) {
        debugPrint('[HC Sync] Heart rate: no new samples since $start');
        return;
      }

      final avg = bpmValues.fold<num>(0, (s, v) => s + v) / bpmValues.length;
      final avgRounded = avg.round();

      try {
        await diaryNotifier.addBodyMetricsFromModal({'heartRate': avgRounded});
        debugPrint('[HC Sync] Heart rate saved: $avgRounded bpm');
        await prefs.setInt(_keyLastSyncHeartRate, now.millisecondsSinceEpoch);
      } catch (e) {
        debugPrint('[HC Sync] Heart rate save failed: $e');
      }
    } catch (e) {
      debugPrint('[HC Sync] _syncHeartRate error: $e');
    }
  }

  // ── Sleep ────────────────────────────────────────────────────────────────────

  Future<void> _syncSleep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      final lastSyncMs = prefs.getInt(_keyLastSyncSleep);
      // If never synced, look back 30 h to catch last night's session.
      // If already synced, only look for records that started after last sync.
      final start = lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs, isUtc: true)
          : now.subtract(const Duration(hours: 30));

      debugPrint('[HC Sync] Sleep: fetching from $start');

      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.SleepSession,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? [];
      if (records.isEmpty) {
        debugPrint('[HC Sync] Sleep: no new records since $start');
        return;
      }

      // Use the most recent record among the new ones
      Map? latest;
      DateTime? latestEnd;
      for (final raw in records) {
        if (raw is! Map) continue;
        final endDt = _parseIso(raw['endTime']);
        if (endDt == null) continue;
        if (latestEnd == null || endDt.isAfter(latestEnd)) {
          latestEnd = endDt;
          latest = raw;
        }
      }

      if (latest == null) return;

      final startDt = _parseIso(latest['startTime']);
      final endDt = _parseIso(latest['endTime']);
      if (startDt == null || endDt == null) return;

      final durationHours = endDt.difference(startDt).inMinutes / 60.0;

      final payload = <String, dynamic>{
        'sleepTime': _toHHmm(startDt),
        'wakeTime': _toHHmm(endDt),
        'duration': durationHours,
      };

      try {
        await diaryNotifier.addSleepFromModal(payload);
        debugPrint(
          '[HC Sync] Sleep saved: ${_toHHmm(startDt)} → ${_toHHmm(endDt)} '
          '(${durationHours.toStringAsFixed(1)} h)',
        );
        await prefs.setInt(_keyLastSyncSleep, now.millisecondsSinceEpoch);
      } catch (e) {
        debugPrint('[HC Sync] Sleep save failed: $e');
      }
    } catch (e) {
      debugPrint('[HC Sync] _syncSleep error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Extract a readable exercise name from a Health Connect exercise record.
  String _exerciseName(Map record) {
    final title = record['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;

    final typeRaw = record['exerciseType'];
    if (typeRaw != null) {
      final numericCode =
          typeRaw is num ? typeRaw.toInt() : int.tryParse(typeRaw.toString());
      if (numericCode != null) {
        return _exerciseTypeCodeMap[numericCode] ?? 'Olahraga ($numericCode)';
      }
    }
    return 'Olahraga';
  }

  /// Best-effort: extract average BPM from exercise-session samples if present.
  int? _avgBpmFromRecord(Map record) {
    final samples = record['samples'];
    if (samples is! List || samples.isEmpty) return null;

    final bpms = <num>[];
    for (final s in samples) {
      if (s is! Map) continue;
      final v = _toNum(s['beatsPerMinute'] ?? s['bpm'] ?? s['value']);
      if (v != null) bpms.add(v);
    }
    if (bpms.isEmpty) return null;

    final avg = bpms.fold<num>(0, (sum, v) => sum + v) / bpms.length;
    return avg.round();
  }

  DateTime? _parseIso(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _toHHmm(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static const Map<int, String> _exerciseTypeCodeMap = {
    0: 'Olahraga Lainnya',
    2: 'Badminton',
    4: 'Baseball',
    5: 'Basket',
    8: 'Bersepeda',
    9: 'Bersepeda Statis',
    10: 'Boot Camp',
    11: 'Tinju',
    13: 'Kalistenik',
    14: 'Kriket',
    16: 'Menari',
    25: 'Elliptical',
    26: 'Kelas Olahraga',
    27: 'Anggar',
    28: 'American Football',
    29: 'Australian Football',
    31: 'Frisbee',
    32: 'Golf',
    33: 'Pernapasan Terpandu',
    34: 'Senam',
    35: 'Handball',
    36: 'HIIT',
    37: 'Hiking',
    38: 'Hoki Es',
    39: 'Seluncur Es',
    44: 'Beladiri',
    46: 'Mendayung',
    47: 'Paralayang',
    48: 'Pilates',
    50: 'Racquetball',
    51: 'Panjat Tebing',
    52: 'Roller Hockey',
    53: 'Rowing',
    54: 'Rowing Machine',
    55: 'Rugby',
    56: 'Lari',
    57: 'Treadmill',
    58: 'Berlayar',
    59: 'Scuba Diving',
    60: 'Seluncur',
    61: 'Ski',
    62: 'Snowboard',
    63: 'Snowshoeing',
    64: 'Sepak Bola',
    65: 'Softball',
    66: 'Squash',
    68: 'Naik Tangga',
    69: 'Mesin Tangga',
    70: 'Latihan Kekuatan',
    71: 'Peregangan',
    72: 'Surfing',
    73: 'Renang Air Terbuka',
    74: 'Renang Kolam',
    75: 'Tenis Meja',
    76: 'Tenis',
    78: 'Voli',
    79: 'Jalan Kaki',
    80: 'Polo Air',
    81: 'Angkat Beban',
    82: 'Kursi Roda',
    83: 'Yoga',
  };
}
