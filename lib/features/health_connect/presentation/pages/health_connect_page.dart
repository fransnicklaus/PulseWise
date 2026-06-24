import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/health_connect/presentation/providers/health_connect_provider.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

class HealthConnectPage extends ConsumerStatefulWidget {
  const HealthConnectPage({super.key});

  @override
  ConsumerState<HealthConnectPage> createState() => _HealthConnectPageState();
}

class _HealthConnectPageState extends ConsumerState<HealthConnectPage> {
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

  final List<HealthConnectDataType> _types = const [
    HealthConnectDataType.Steps,
    HealthConnectDataType.ExerciseSession,
    HealthConnectDataType.HeartRate,
    HealthConnectDataType.SleepSession,
  ];

  bool _showRaw = false;
  bool _isBusy = false;
  String? _activeAction;
  bool? _isApiSupported;
  bool? _isInstalled;
  bool? _hasPermissions;
  String _lastAction = 'Belum ada aksi';
  String _rawData = '-';
  String _statusNote =
      'Ikuti panduan ini agar PulseWise bisa membaca data kesehatan dari wearable Anda.';
  Map<String, dynamic>? _prettyData;
  bool _isSyncingBackendHealthConnectState = false;
  bool _didPersistConnectedStatusThisVisit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkAll(
        silent: true,
        updateStatusNote: false,
        updateResult: false,
      );
    });
  }

  Future<void> _runBusyAction(
    String actionLabel,
    Future<void> Function() action,
  ) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _activeAction = actionLabel;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _activeAction = null;
        });
      }
    }
  }

  Future<void> _checkAll({
    bool silent = false,
    bool updateStatusNote = true,
    bool updateResult = true,
  }) async {
    await _runBusyAction('Memeriksa semua status', () async {
      try {
        final supported = await HealthConnectFactory.isApiSupported();
        bool? installed;
        bool? granted;

        if (supported) {
          installed = await HealthConnectFactory.isAvailable();
          if (installed) {
            granted = await HealthConnectFactory.hasPermissions(
              _types,
              readOnly: true,
            );
          }
        }

        final nextStatusNote = supported
            ? installed == true
                ? granted == true
                    ? 'Health Connect sudah siap digunakan di PulseWise.'
                    : 'Health Connect sudah terpasang, tetapi izin data belum diberikan.'
                : 'Perangkat mendukung, tetapi aplikasi Health Connect belum terpasang.'
            : 'Perangkat ini belum mendukung Health Connect.';

        if (!mounted) return;
        setState(() {
          _isApiSupported = supported;
          _isInstalled = installed;
          _hasPermissions = granted;
          if (updateStatusNote) {
            _statusNote = nextStatusNote;
          }
        });
        if (updateResult) {
          _setResult(
            action: 'Periksa Semua Status',
            data: {
              'supported': supported,
              'installed': installed,
              'permissionsGranted': granted,
            },
          );
        }
        await _persistConnectedStatusIfNeeded();
      } catch (e) {
        if (!mounted) return;
        if (updateStatusNote) {
          setState(() {
            _statusNote = 'Gagal memeriksa status: $e';
          });
        }
        if (updateResult) {
          _setResult(
            action: 'Periksa Semua Status',
            data: {'error': e.toString()},
          );
        }
        if (!silent) {
          AppToast.error(context, 'Gagal memeriksa status Health Connect');
        }
      }
    });
  }

  Future<void> _checkApiSupported() async {
    await _runBusyAction('Memeriksa dukungan perangkat', () async {
      try {
        final supported = await HealthConnectFactory.isApiSupported();
        if (!mounted) return;
        setState(() {
          _isApiSupported = supported;
          _statusNote = supported
              ? 'Perangkat mendukung Health Connect.'
              : 'Perangkat belum mendukung Health Connect.';
        });
        _setResult(
          action: 'Periksa Dukungan Perangkat',
          data: {'supported': supported},
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal memeriksa dukungan perangkat: $e';
        });
        _setResult(
          action: 'Periksa Dukungan Perangkat',
          data: {'error': e.toString()},
        );
        AppToast.error(context, 'Gagal memeriksa dukungan perangkat');
      }
    });
  }

  Future<void> _checkInstalled() async {
    await _runBusyAction('Memeriksa aplikasi Health Connect', () async {
      try {
        final installed = await HealthConnectFactory.isAvailable();
        if (!mounted) return;
        setState(() {
          _isInstalled = installed;
          _statusNote = installed
              ? 'Aplikasi Health Connect sudah terpasang.'
              : 'Aplikasi Health Connect belum terpasang.';
        });
        _setResult(
          action: 'Periksa Aplikasi Health Connect',
          data: {'installed': installed},
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal memeriksa aplikasi Health Connect: $e';
        });
        _setResult(
          action: 'Periksa Aplikasi Health Connect',
          data: {'error': e.toString()},
        );
        AppToast.error(context, 'Gagal memeriksa aplikasi Health Connect');
      }
    });
  }

  Future<void> _installHealthConnect() async {
    await _runBusyAction('Membuka halaman instalasi', () async {
      try {
        await HealthConnectFactory.installHealthConnect();
        if (!mounted) return;
        setState(() {
          _statusNote =
              'Halaman instalasi Health Connect sedang dibuka. Silakan instal aplikasinya terlebih dahulu.';
        });
        _setResult(
          action: 'Instal Health Connect',
          data: {'message': 'Install activity started'},
        );
        AppToast.info(context, 'Membuka halaman instalasi Health Connect...');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal membuka halaman instalasi: $e';
        });
        _setResult(
          action: 'Instal Health Connect',
          data: {'error': e.toString()},
        );
        AppToast.error(context, e.toString());
      }
    });
  }

  Future<void> _openSettings() async {
    await _runBusyAction('Membuka pengaturan Health Connect', () async {
      try {
        await HealthConnectFactory.openHealthConnectSettings();
        if (!mounted) return;
        setState(() {
          _statusNote =
              'Pengaturan Health Connect sedang dibuka. Silakan aktifkan izin yang diperlukan.';
        });
        _setResult(
          action: 'Buka Pengaturan Health Connect',
          data: {'message': 'Settings activity started'},
        );
        AppToast.success(context, 'Membuka pengaturan Health Connect');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal membuka pengaturan Health Connect: $e';
        });
        _setResult(
          action: 'Buka Pengaturan Health Connect',
          data: {'error': e.toString()},
        );
        AppToast.error(context, e.toString());
      }
    });
  }

  Future<void> _checkPermissions() async {
    await _runBusyAction('Memeriksa izin data', () async {
      try {
        final granted = await HealthConnectFactory.hasPermissions(
          _types,
          readOnly: true,
        );
        if (!mounted) return;
        setState(() {
          _hasPermissions = granted;
          _statusNote = granted
              ? 'Izin data sudah diberikan.'
              : 'Izin data belum diberikan.';
        });
        _setResult(
          action: 'Periksa Izin Data',
          data: {'granted': granted},
        );
        await _persistConnectedStatusIfNeeded();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal memeriksa izin data: $e';
        });
        _setResult(
          action: 'Periksa Izin Data',
          data: {'error': e.toString()},
        );
        AppToast.error(context, 'Gagal memeriksa izin data');
      }
    });
  }

  Future<void> _requestPermissions() async {
    await _runBusyAction('Meminta izin data', () async {
      try {
        final granted = await HealthConnectFactory.requestPermissions(
          _types,
          readOnly: true,
        );
        if (!mounted) return;
        setState(() {
          _hasPermissions = granted;
          _statusNote = granted
              ? 'Izin data berhasil diberikan.'
              : 'Izin data belum diberikan. Silakan coba lagi.';
        });
        _setResult(
          action: 'Minta Izin Data',
          data: {'granted': granted},
        );
        await _persistConnectedStatusIfNeeded();
        if (!mounted) return;
        if (granted) {
          AppToast.success(context, 'Izin Health Connect berhasil diberikan');
        } else {
          AppToast.info(context, 'Izin belum diberikan');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusNote = 'Gagal meminta izin data: $e';
        });
        _setResult(
          action: 'Minta Izin Data',
          data: {'error': e.toString()},
        );
        AppToast.error(context, e.toString());
      }
    });
  }

  Future<void> _getRecord() async {
    await _runBusyAction('Mengambil semua data', () async {
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
        _setResult(action: 'Ambil Semua Data', data: typePoints);
      } catch (e, s) {
        _setResult(
          action: 'Ambil Semua Data',
          data: {'error': e.toString(), 'stack': s.toString()},
        );
      }
    });
  }

  Future<void> _getTodaySteps() async {
    await _runBusyAction('Mengambil langkah hari ini', () async {
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
          action: 'Lihat Langkah Hari Ini',
          data: {
            'recordCount': records.length,
            'totalSteps': total,
            'start': start.toIso8601String(),
            'end': now.toIso8601String(),
          },
        );
      } catch (e, s) {
        _setResult(
          action: 'Lihat Langkah Hari Ini',
          data: {'error': e.toString(), 'stack': s.toString()},
        );
      }
    });
  }

  Future<void> _getHeartRateData() async {
    await _runBusyAction('Mengambil data detak jantung', () async {
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
                sample['beatsPerMinute'] ?? sample['bpm'] ?? sample['value'],
              );
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
          action: 'Lihat Data Detak Jantung',
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
          action: 'Lihat Data Detak Jantung',
          data: {'error': e.toString(), 'stack': s.toString()},
        );
      }
    });
  }

  Future<void> _getSleepData() async {
    await _runBusyAction('Mengambil data tidur', () async {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      try {
        final result = await HealthConnectFactory.getRecord(
          type: HealthConnectDataType.SleepSession,
          startTime: start,
          endTime: now,
        );

        final records = (result['records'] as List?) ?? const [];
        final sleepDetails = <Map<String, dynamic>>[];

        for (final record in records) {
          if (record is! Map) continue;

          sleepDetails.add({
            'title': record['title'],
            'notes': record['notes'],
            'startTime': record['startTime'],
            'endTime': record['endTime'],
          });
        }

        _setResult(
          action: 'Lihat Data Tidur',
          data: {
            'recordCount': records.length,
            'sleepDetails': sleepDetails,
            'start': start.toIso8601String(),
            'end': now.toIso8601String(),
            'records': records,
          },
        );
      } catch (e, s) {
        _setResult(
          action: 'Lihat Data Tidur',
          data: {'error': e.toString(), 'stack': s.toString()},
        );
      }
    });
  }

  Future<void> _getExerciseData() async {
    await _runBusyAction('Mengambil data aktivitas', () async {
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
          action: 'Lihat Data Aktivitas',
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
          action: 'Lihat Data Aktivitas',
          data: {'error': e.toString(), 'stack': s.toString()},
        );
      }
    });
  }

  String _statusLabel(bool? value, String positive, String negative) {
    if (value == null) return 'Belum dicek';
    return value ? positive : negative;
  }

  Color _statusColor(bool? value) {
    if (value == null) return const Color(0xFF64748B);
    return value ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
  }

  Color _statusBackground(bool? value) {
    if (value == null) return const Color(0xFFF1F5F9);
    return value ? const Color(0xFFECFDF3) : const Color(0xFFFEF2F2);
  }

  bool? _readyStatus() {
    if (_isApiSupported == null &&
        _isInstalled == null &&
        _hasPermissions == null) {
      return null;
    }

    return _isApiSupported == true &&
        _isInstalled == true &&
        _hasPermissions == true;
  }

  Future<void> _persistConnectedStatusIfNeeded() async {
    final ready = _readyStatus() == true;
    if (!ready ||
        _isSyncingBackendHealthConnectState ||
        _didPersistConnectedStatusThisVisit) {
      return;
    }

    final currentProfile = ref.read(patientProfileProvider).valueOrNull;
    if (currentProfile?.isHealthConnectConnected == true &&
        currentProfile?.healthConnectPreference == 'connect_now') {
      _didPersistConnectedStatusThisVisit = true;
      return;
    }

    _isSyncingBackendHealthConnectState = true;
    try {
      await ref.read(healthConnectSetupApiProvider).updateHealthConnectSetup(
            healthConnectPreference: 'connect_now',
            healthConnectStatus: 'connected',
          );
      ref.invalidate(patientProfileProvider);
      _didPersistConnectedStatusThisVisit = true;
      debugPrint(
        '[HealthConnectPage] Backend status updated to connect_now/connected.',
      );
    } catch (e) {
      debugPrint(
        '[HealthConnectPage] Failed to persist connected status: $e',
      );
    } finally {
      _isSyncingBackendHealthConnectState = false;
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
          .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
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

  void _setResult({
    required String action,
    required Map<String, dynamic> data,
  }) {
    setState(() {
      _lastAction = action;
      _prettyData = data;
      _rawData = const JsonEncoder.withIndent('  ').convert(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Koneksi Wearable',
        subtitle: 'Hubungkan PulseWise dengan smartwatch Anda',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideOverviewCard(
                isBusy: _isBusy,
                activeAction: _activeAction,
                statusNote: _statusNote,
                onCheckAll: _checkAll,
              ),
              const SizedBox(height: 16),
              _GuideStepCard(
                number: '1',
                title: 'Periksa apakah perangkat mendukung',
                description:
                    'Mulai dengan memastikan ponsel Anda mendukung Health Connect.',
                statusLabel: _statusLabel(
                  _isApiSupported,
                  'Didukung',
                  'Tidak didukung',
                ),
                statusColor: _statusColor(_isApiSupported),
                statusBackground: _statusBackground(_isApiSupported),
                actions: [
                  _GuideActionButton(
                    label: 'Periksa Dukungan',
                    onPressed: _isBusy ? null : _checkApiSupported,
                  ),
                ],
                expandableDetails: null,
              ),
              const SizedBox(height: 12),
              _GuideStepCard(
                number: '2',
                title: 'Pastikan aplikasi Health Connect sudah ada',
                description:
                    'Jika belum terpasang, buka halaman instalasi lalu pasang aplikasinya terlebih dahulu.',
                statusLabel: _statusLabel(
                  _isInstalled,
                  'Sudah terpasang',
                  'Belum terpasang',
                ),
                statusColor: _statusColor(_isInstalled),
                statusBackground: _statusBackground(_isInstalled),
                actions: [
                  _GuideActionButton(
                    label: 'Periksa Aplikasi',
                    onPressed: _isBusy ? null : _checkInstalled,
                    isPrimary: false,
                  ),
                  _GuideActionButton(
                    label: 'Instal Health Connect',
                    onPressed: _isBusy ? null : _installHealthConnect,
                  ),
                ],
                expandableDetails: null,
              ),
              const SizedBox(height: 12),
              _GuideStepCard(
                number: '3',
                title: 'Buka pengaturan Health Connect',
                description:
                    'Masuk ke pengaturan Health Connect untuk melihat izin yang tersedia untuk PulseWise.',
                actions: [
                  _GuideActionButton(
                    label: 'Buka Pengaturan',
                    onPressed: _isBusy ? null : _openSettings,
                  ),
                ],
                statusLabel: null,
                statusColor: null,
                statusBackground: null,
                expandableDetails: null,
              ),
              const SizedBox(height: 12),
              const _GuideStepCard(
                number: '4',
                title: 'Pastikan aplikasi wearable dapat mengirim data',
                description:
                    'Periksa aplikasi wearable Anda dan pastikan aplikasi tersebut diizinkan menulis atau menyinkronkan data ke Health Connect.',
                statusLabel: null,
                statusColor: null,
                statusBackground: null,
                actions: [],
                expandableDetails: _GuideExpandableDetailsContent(
                  hint:
                      'Detail ini masih contoh sementara dan nanti bisa kita sesuaikan dengan alur yang benar.',
                  steps: [
                    'Buka aplikasi wearable yang Anda gunakan, misalnya Samsung Health, Mi Fitness, Garmin Connect, atau aplikasi jam tangan lainnya yang tersedia dalam Google Play Store.',
                    'Masuk ke menu pengaturan, integrasi, atau izin sinkronisasi di aplikasi tersebut.',
                    'Cari opsi yang berkaitan dengan Health Connect, sinkronisasi kesehatan, atau berbagi data kesehatan.',
                    'Pastikan kategori seperti langkah, detak jantung, tidur, dan aktivitas diizinkan untuk dikirim ke Health Connect.',
                    'Setelah selesai, kembali ke PulseWise lalu lanjutkan ke langkah berikutnya.',
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GuideStepCard(
                number: '5',
                title: 'Berikan izin akses data',
                description:
                    'Izinkan PulseWise membaca langkah, detak jantung, tidur, dan aktivitas agar sinkronisasi berjalan.',
                statusLabel: _statusLabel(
                  _hasPermissions,
                  'Sudah diizinkan',
                  'Belum diizinkan',
                ),
                statusColor: _statusColor(_hasPermissions),
                statusBackground: _statusBackground(_hasPermissions),
                actions: [
                  _GuideActionButton(
                    label: 'Cek Izin',
                    onPressed: _isBusy ? null : _checkPermissions,
                    isPrimary: false,
                  ),
                  _GuideActionButton(
                    label: 'Berikan Izin',
                    onPressed: _isBusy ? null : _requestPermissions,
                  ),
                ],
                expandableDetails: const _GuideExpandableDetailsContent(
                  hint:
                      'Ikuti urutan izin di bawah ini agar PulseWise bisa membaca data dari Health Connect.',
                  steps: [
                    'Masuk ke halaman izin aplikasi di Health Connect, lalu pilih PulseWise dari daftar aplikasi.',
                    'Buka bagian pengaturan akses data untuk PulseWise agar kategori data yang dibaca bisa diatur.',
                    'Aktifkan akses baca untuk langkah, detak jantung, tidur, dan aktivitas, lalu kembali ke PulseWise untuk menekan Cek Izin.',
                  ],
                  imageSteps: [
                    _GuideImageStep(
                      label: 'Langkah 1',
                      imagePath: 'assets/images/step_1.jpg',
                    ),
                    _GuideImageStep(
                      label: 'Langkah 2',
                      imagePath: 'assets/images/step_2.jpg',
                    ),
                    _GuideImageStep(
                      label: 'Langkah 3',
                      imagePath: 'assets/images/step_3.jpg',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GuideStepCard(
                number: '6',
                title: 'Kembali ke PulseWise',
                description:
                    'Jika semua status sudah hijau, PulseWise siap membaca data dari wearable Anda melalui Health Connect.',
                statusLabel: _statusLabel(
                  _readyStatus(),
                  'Siap digunakan',
                  'Belum siap',
                ),
                statusColor: _statusColor(_readyStatus()),
                statusBackground: _statusBackground(_readyStatus()),
                actions: const [],
                expandableDetails: null,
              ),
              const SizedBox(height: 24),
              // _DataViewerCard(
              //   isBusy: _isBusy,
              //   onGetRecord: _getRecord,
              //   onGetTodaySteps: _getTodaySteps,
              //   onGetHeartRateData: _getHeartRateData,
              //   onGetExerciseData: _getExerciseData,
              //   onGetSleepData: _getSleepData,
              //   showRaw: _showRaw,
              //   rawData: _rawData,
              //   prettyData: _prettyData,
              //   lastAction: _lastAction,
              //   onSelectPretty: () => setState(() => _showRaw = false),
              //   onSelectRaw: () => setState(() => _showRaw = true),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideOverviewCard extends StatelessWidget {
  final bool isBusy;
  final String? activeAction;
  final String statusNote;
  final Future<void> Function() onCheckAll;

  const _GuideOverviewCard({
    required this.isBusy,
    required this.activeAction,
    required this.statusNote,
    required this.onCheckAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideIconBox(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koneksi Wearable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE64060),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hubungkan PulseWise dengan smartwatch Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'PulseWise dapat membaca data langkah, detak jantung, tidur, dan aktivitas dari wearable yang terhubung ke Health Connect.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          // const SizedBox(height: 14),
          // const Wrap(
          //   spacing: 8,
          //   runSpacing: 8,
          //   children: [
          //     _InfoChip(label: 'Langkah'),
          //     _InfoChip(label: 'Detak Jantung'),
          //     _InfoChip(label: 'Tidur'),
          //     _InfoChip(label: 'Aktivitas'),
          //   ],
          // ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : onCheckAll,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isBusy && activeAction != null
                    ? activeAction!
                    : 'Periksa Semua Sekarang',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // const SizedBox(height: 16),
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(14),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF8FAFC),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(color: const Color(0xFFE2E8F0)),
          //   ),
          //   child: Text(
          //     statusNote,
          //     style: const TextStyle(
          //       fontSize: 15,
          //       fontWeight: FontWeight.w600,
          //       color: Color(0xFF475569),
          //       height: 1.5,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _GuideIconBox extends StatelessWidget {
  const _GuideIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.watch_outlined,
        size: 30,
        color: Color(0xFFE64060),
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String? statusLabel;
  final Color? statusColor;
  final Color? statusBackground;
  final List<Widget> actions;
  final _GuideExpandableDetailsContent? expandableDetails;

  const _GuideStepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.actions,
    required this.expandableDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE64060),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (statusLabel != null &&
                            statusColor != null &&
                            statusBackground != null) ...[
                          const SizedBox(width: 10),
                          _StepStatusChip(
                            label: statusLabel!,
                            textColor: statusColor!,
                            backgroundColor: statusBackground!,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
          if (expandableDetails != null) ...[
            const SizedBox(height: 14),
            _ExpandableGuideDetails(content: expandableDetails!),
          ],
        ],
      ),
    );
  }
}

class _GuideActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _GuideActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary ? Colors.white : const Color(0xFF475569);
    final backgroundColor = isPrimary ? const Color(0xFFE64060) : Colors.white;
    final sideColor =
        isPrimary ? const Color(0xFFE64060) : const Color(0xFFD9E2EC);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          disabledForegroundColor: const Color(0xFF94A3B8),
          disabledBackgroundColor: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: sideColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StepStatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StepStatusChip({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}

class _GuideExpandableDetailsContent {
  final String hint;
  final List<String> steps;
  final List<_GuideImageStep> imageSteps;

  const _GuideExpandableDetailsContent({
    required this.hint,
    required this.steps,
    this.imageSteps = const [],
  });
}

class _GuideImageStep {
  final String label;
  final String imagePath;

  const _GuideImageStep({
    required this.label,
    required this.imagePath,
  });
}

class _ExpandableGuideDetails extends StatefulWidget {
  final _GuideExpandableDetailsContent content;

  const _ExpandableGuideDetails({required this.content});

  @override
  State<_ExpandableGuideDetails> createState() =>
      _ExpandableGuideDetailsState();
}

class _ExpandableGuideDetailsState extends State<_ExpandableGuideDetails> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isExpanded) ...[
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            //   child: Text(
            //     widget.content.hint,
            //     style: const TextStyle(
            //       fontSize: 13,
            //       fontWeight: FontWeight.w500,
            //       color: Color(0xFF64748B),
            //       height: 1.5,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            ...widget.content.steps.asMap().entries.expand((entry) {
              final widgets = <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE7E7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE64060),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];

              if (entry.key < widget.content.imageSteps.length) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: _GuideImageStepCard(
                      step: widget.content.imageSteps[entry.key],
                    ),
                  ),
                );
              }

              return widgets;
            }),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded
                        ? 'Sembunyikan detail'
                        : widget.content.imageSteps.isNotEmpty
                            ? 'Lihat detail dan gambar'
                            : 'Lihat detail langkah',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideImageStepCard extends StatelessWidget {
  final _GuideImageStep step;

  const _GuideImageStepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFFFE7E7),
          //     borderRadius: BorderRadius.circular(999),
          //   ),
          //   child: Text(
          //     step.label,
          //     style: const TextStyle(
          //       fontSize: 12,
          //       fontWeight: FontWeight.w800,
          //       color: Color(0xFFE64060),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Image.asset(
                step.imagePath,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataViewerCard extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onGetRecord;
  final VoidCallback onGetTodaySteps;
  final VoidCallback onGetHeartRateData;
  final VoidCallback onGetExerciseData;
  final VoidCallback onGetSleepData;
  final bool showRaw;
  final String rawData;
  final Map<String, dynamic>? prettyData;
  final String lastAction;
  final VoidCallback onSelectPretty;
  final VoidCallback onSelectRaw;

  const _DataViewerCard({
    required this.isBusy,
    required this.onGetRecord,
    required this.onGetTodaySteps,
    required this.onGetHeartRateData,
    required this.onGetExerciseData,
    required this.onGetSleepData,
    required this.showRaw,
    required this.rawData,
    required this.prettyData,
    required this.lastAction,
    required this.onSelectPretty,
    required this.onSelectRaw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cek Data yang Sudah Tersambung',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setelah izin diberikan, gunakan tombol di bawah ini untuk melihat apakah data wearable Anda sudah terbaca di PulseWise.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Ambil Semua Data',
                onTap: isBusy ? null : onGetRecord,
              ),
              _ActionButton(
                label: 'Langkah Hari Ini',
                onTap: isBusy ? null : onGetTodaySteps,
              ),
              _ActionButton(
                label: 'Detak Jantung',
                onTap: isBusy ? null : onGetHeartRateData,
              ),
              _ActionButton(
                label: 'Aktivitas',
                onTap: isBusy ? null : onGetExerciseData,
              ),
              _ActionButton(
                label: 'Tidur',
                onTap: isBusy ? null : onGetSleepData,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hasil Pemeriksaan',
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
                        label: 'Ringkas',
                        selected: !showRaw,
                        onTap: onSelectPretty,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeButton(
                        label: 'Raw',
                        selected: showRaw,
                        onTap: onSelectRaw,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (showRaw)
                  SelectableText(
                    rawData,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  )
                else
                  _BeautifulResult(data: prettyData, lastAction: lastAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF334155),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
        'Belum ada data. Coba salah satu tombol di atas.',
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
              color: Colors.white,
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

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
