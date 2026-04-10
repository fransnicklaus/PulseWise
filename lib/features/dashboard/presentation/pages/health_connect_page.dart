import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';

class HealthConnectPage extends StatefulWidget {
  const HealthConnectPage({super.key});

  @override
  State<HealthConnectPage> createState() => _HealthConnectPageState();
}

class _HealthConnectPageState extends State<HealthConnectPage> {
  static const Map<int, String> _exerciseTypeCodeMap = {
    0: 'Other Workout',
    2: 'Badminton',
    4: 'Baseball',
    5: 'Basketball',
    8: 'Biking',
    9: 'Stationary Biking',
    10: 'Boot Camp',
    11: 'Boxing',
    13: 'Calisthenics',
    14: 'Cricket',
    16: 'Dancing',
    25: 'Elliptical',
    26: 'Exercise Class',
    27: 'Fencing',
    28: 'American Football',
    29: 'Australian Football',
    31: 'Frisbee Disc',
    32: 'Golf',
    33: 'Guided Breathing',
    34: 'Gymnastics',
    35: 'Handball',
    36: 'HIIT',
    37: 'Hiking',
    38: 'Ice Hockey',
    39: 'Ice Skating',
    44: 'Martial Arts',
    46: 'Paddling',
    47: 'Paragliding',
    48: 'Pilates',
    50: 'Racquetball',
    51: 'Rock Climbing',
    52: 'Roller Hockey',
    53: 'Rowing',
    54: 'Rowing Machine',
    55: 'Rugby',
    56: 'Running',
    57: 'Treadmill Running',
    58: 'Sailing',
    59: 'Scuba Diving',
    60: 'Skating',
    61: 'Skiing',
    62: 'Snowboarding',
    63: 'Snowshoeing',
    64: 'Soccer',
    65: 'Softball',
    66: 'Squash',
    68: 'Stair Climbing',
    69: 'Stair Climbing Machine',
    70: 'Strength Training',
    71: 'Stretching',
    72: 'Surfing',
    73: 'Open Water Swimming',
    74: 'Pool Swimming',
    75: 'Table Tennis',
    76: 'Tennis',
    78: 'Volleyball',
    79: 'Walking',
    80: 'Water Polo',
    81: 'Weightlifting',
    82: 'Wheelchair',
    83: 'Yoga',
  };

  bool _showRaw = false;
  String _lastAction = 'Belum ada aksi';
  Map<String, dynamic>? _prettyData;
  String _rawData = '-';

  final List<HealthConnectDataType> _types = [
    HealthConnectDataType.Steps,
    HealthConnectDataType.ExerciseSession,
    HealthConnectDataType.HeartRate,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health Connect',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              _ActionButton(
                label: 'isApiSupported',
                onTap: _checkApiSupported,
              ),
              _ActionButton(
                label: 'Check installed',
                onTap: _checkInstalled,
              ),
              _ActionButton(
                label: 'Install Health Connect',
                onTap: _installHealthConnect,
              ),
              _ActionButton(
                label: 'Open Health Connect Settings',
                onTap: _openSettings,
              ),
              _ActionButton(
                label: 'Has Permissions',
                onTap: _hasPermissions,
              ),
              _ActionButton(
                label: 'Request Permissions',
                onTap: _requestPermissions,
              ),
              _ActionButton(
                label: 'Get Record',
                onTap: _getRecord,
              ),
              _ActionButton(
                label: "Get Today's Steps",
                onTap: _getTodaySteps,
              ),
              _ActionButton(
                label: 'View Heart Rate Data',
                onTap: _getHeartRateData,
              ),
              _ActionButton(
                label: 'View Exercise Data',
                onTap: _getExerciseData,
              ),
              const SizedBox(height: 18),
              _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Result Viewer',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Beautiful',
                  selected: !_showRaw,
                  onTap: () => setState(() => _showRaw = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'Raw',
                  selected: _showRaw,
                  onTap: () => setState(() => _showRaw = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showRaw)
            SelectableText(
              _rawData,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            _BeautifulResult(data: _prettyData, lastAction: _lastAction),
        ],
      ),
    );
  }

  Future<void> _checkApiSupported() async {
    final result = await HealthConnectFactory.isApiSupported();
    _setResult(action: 'isApiSupported', data: {'supported': result});
  }

  Future<void> _checkInstalled() async {
    final result = await HealthConnectFactory.isAvailable();
    _setResult(action: 'Check installed', data: {'installed': result});
  }

  Future<void> _installHealthConnect() async {
    try {
      await HealthConnectFactory.installHealthConnect();
      _setResult(
        action: 'Install Health Connect',
        data: {'message': 'Install activity started'},
      );
      if (mounted) {
        AppToast.info(context, 'Membuka halaman instalasi Health Connect...');
      }
    } catch (e) {
      _setResult(
        action: 'Install Health Connect',
        data: {'error': e.toString()},
      );
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  Future<void> _openSettings() async {
    try {
      await HealthConnectFactory.openHealthConnectSettings();
      _setResult(
        action: 'Open Health Connect Settings',
        data: {'message': 'Settings activity started'},
      );
      if (mounted) {
        AppToast.success(context, 'Membuka halaman pengaturan Health Connect');
      }
    } catch (e) {
      _setResult(
        action: 'Open Health Connect Settings',
        data: {'error': e.toString()},
      );
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  Future<void> _hasPermissions() async {
    final granted = await HealthConnectFactory.hasPermissions(
      _types,
      readOnly: true,
    );

    _setResult(
      action: 'Has Permissions',
      data: {'granted': granted},
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final granted = await HealthConnectFactory.requestPermissions(
        _types,
        readOnly: true,
      );
      _setResult(
        action: 'Request Permissions',
        data: {'granted': granted},
      );
    } catch (e) {
      _setResult(
        action: 'Request Permissions',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> _getRecord() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    try {
      final requests = <Future>[];
      final typePoints = <String, dynamic>{};
      for (final type in _types) {
        requests.add(
          HealthConnectFactory.getRecord(
            type: type,
            startTime: start,
            endTime: now,
          ).then((value) => typePoints[type.name] = value),
        );
      }
      await Future.wait(requests);
      _setResult(action: 'Get Record', data: typePoints);
    } catch (e, s) {
      _setResult(
        action: 'Get Record',
        data: {'error': e.toString(), 'stack': s.toString()},
      );
    }
  }

  Future<void> _getTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.Steps,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? const [];
      num total = 0;
      for (final record in records) {
        final dynamic count = (record as Map?)?['count'];
        if (count is num) total += count;
      }

      _setResult(
        action: "Get Today's Steps",
        data: {
          'recordCount': records.length,
          'totalSteps': total,
          'start': start.toIso8601String(),
          'end': now.toIso8601String(),
        },
      );
    } catch (e, s) {
      _setResult(
        action: "Get Today's Steps",
        data: {'error': e.toString(), 'stack': s.toString()},
      );
    }
  }

  Future<void> _getHeartRateData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));

    try {
      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.HeartRate,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? const [];
      final bpmValues = <num>[];

      for (final record in records) {
        if (record is! Map) continue;

        final directValue = _toNum(record['beatsPerMinute'] ?? record['bpm']);
        if (directValue != null) bpmValues.add(directValue);

        final samples = record['samples'];
        if (samples is List) {
          for (final sample in samples) {
            if (sample is! Map) continue;
            final sampleValue = _toNum(
                sample['beatsPerMinute'] ?? sample['bpm'] ?? sample['value']);
            if (sampleValue != null) bpmValues.add(sampleValue);
          }
        }
      }

      num? minBpm;
      num? maxBpm;
      num avgBpm = 0;

      if (bpmValues.isNotEmpty) {
        minBpm = bpmValues.reduce((a, b) => a < b ? a : b);
        maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);
        final total = bpmValues.fold<num>(0, (sum, value) => sum + value);
        avgBpm = total / bpmValues.length;
      }

      _setResult(
        action: 'View Heart Rate Data',
        data: {
          'recordCount': records.length,
          'sampleCount': bpmValues.length,
          'minBpm': minBpm,
          'maxBpm': maxBpm,
          'avgBpm': bpmValues.isEmpty ? null : avgBpm.toStringAsFixed(1),
          'start': start.toIso8601String(),
          'end': now.toIso8601String(),
          'records': records,
        },
      );
    } catch (e, s) {
      _setResult(
        action: 'View Heart Rate Data',
        data: {'error': e.toString(), 'stack': s.toString()},
      );
    }
  }

  Future<void> _getExerciseData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));

    try {
      final result = await HealthConnectFactory.getRecord(
        type: HealthConnectDataType.ExerciseSession,
        startTime: start,
        endTime: now,
      );

      final records = (result['records'] as List?) ?? const [];
      final exerciseTypes = <String>{};
      final exerciseDetails = <Map<String, dynamic>>[];

      for (final record in records) {
        if (record is! Map) continue;

        final typeRaw = record['exerciseType'];
        final typeLabel = _formatExerciseType(typeRaw);
        exerciseTypes.add(typeLabel);

        exerciseDetails.add({
          'exerciseType': typeLabel,
          'exerciseTypeRaw': typeRaw,
          'title': record['title'],
          'notes': record['notes'],
          'startTime': record['startTime'],
          'endTime': record['endTime'],
        });
      }

      _setResult(
        action: 'View Exercise Data',
        data: {
          'recordCount': records.length,
          'uniqueExerciseTypes': exerciseTypes.toList(),
          'exerciseDetails': exerciseDetails,
          'start': start.toIso8601String(),
          'end': now.toIso8601String(),
          'records': records,
        },
      );
    } catch (e, s) {
      _setResult(
        action: 'View Exercise Data',
        data: {'error': e.toString(), 'stack': s.toString()},
      );
    }
  }

  String _formatExerciseType(dynamic type) {
    if (type == null) return 'Unknown';

    final raw = type.toString();
    final upper = raw.toUpperCase();

    final numericCode = type is num ? type.toInt() : int.tryParse(raw);
    if (numericCode != null) {
      final knownLabel = _exerciseTypeCodeMap[numericCode];
      if (knownLabel != null) return knownLabel;
      return 'Exercise type code $numericCode';
    }

    if (upper.startsWith('EXERCISE_TYPE_')) {
      final words = upper
          .replaceFirst('EXERCISE_TYPE_', '')
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) =>
              '${part[0]}${part.substring(1).toLowerCase()}')
          .toList();
      return words.join(' ');
    }

    return raw;
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  void _setResult(
      {required String action, required Map<String, dynamic> data}) {
    setState(() {
      _lastAction = action;
      _prettyData = data;
      _rawData = const JsonEncoder.withIndent('  ').convert(data);
    });
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5B4A96),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE64060) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BeautifulResult extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String lastAction;

  const _BeautifulResult({required this.data, required this.lastAction});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Text(
        'Belum ada data. Coba salah satu aksi di atas.',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi terakhir: $lastAction',
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...data!.entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    entry.value.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
