import 'dart:async';

import 'package:flutter/material.dart';

typedef GejalaSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef KonsumsiSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef AktivitasSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef MetriksSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);

class DiarySectionBottomSheet extends StatefulWidget {
  final String title;
  final ScrollController? scrollController;
  final GejalaSubmitCallback? onSubmitGejala;
  final KonsumsiSubmitCallback? onSubmitKonsumsi;
  final AktivitasSubmitCallback? onSubmitAktivitas;
  final MetriksSubmitCallback? onSubmitMetriks;

  const DiarySectionBottomSheet({
    super.key,
    required this.title,
    this.scrollController,
    this.onSubmitGejala,
    this.onSubmitKonsumsi,
    this.onSubmitAktivitas,
    this.onSubmitMetriks,
  });

  @override
  State<DiarySectionBottomSheet> createState() =>
      _DiarySectionBottomSheetState();
}

class _DiarySectionBottomSheetState extends State<DiarySectionBottomSheet> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _symptomSearchController =
      TextEditingController();
  final TextEditingController _activitySearchController =
      TextEditingController();
  final TextEditingController _activityHeartRateController =
      TextEditingController();
  final TextEditingController _symptomOtherController = TextEditingController();
  final TextEditingController _symptomDescriptionController =
      TextEditingController();
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _mealPortionController = TextEditingController();
  final TextEditingController _mealDescriptionController =
      TextEditingController();

  final List<String> _activityOptions = const [
    'Other Workout',
    'Badminton',
    'Baseball',
    'Basketball',
    'Biking',
    'Stationary Biking',
    'Boot Camp',
    'Boxing',
    'Calisthenics',
    'Cricket',
    'Dancing',
    'Elliptical',
    'Exercise Class',
    'Fencing',
    'American Football',
    'Australian Football',
    'Frisbee Disc',
    'Golf',
    'Guided Breathing',
    'Gymnastics',
    'Handball',
    'HIIT',
    'Hiking',
    'Ice Hockey',
    'Ice Skating',
    'Martial Arts',
    'Paddling',
    'Paragliding',
    'Pilates',
    'Racquetball',
    'Rock Climbing',
    'Roller Hockey',
    'Rowing',
    'Rowing Machine',
    'Rugby',
    'Running',
    'Treadmill Running',
    'Sailing',
    'Scuba Diving',
    'Skating',
    'Skiing',
    'Snowboarding',
    'Snowshoeing',
    'Soccer',
    'Softball',
    'Squash',
    'Stair Climbing',
    'Stair Climbing Machine',
    'Strength Training',
    'Stretching',
    'Surfing',
    'Open Water Swimming',
    'Pool Swimming',
    'Table Tennis',
    'Tennis',
    'Volleyball',
    'Walking',
    'Water Polo',
    'Weightlifting',
    'Wheelchair',
    'Yoga',
  ];

  final List<String> _symptomOptions = const [
    'Sulit Bernafas',
    'Kaki Bengkak',
    'Lemas',
    'Sulit Tidur',
    'Perut Bengkak',
    'Sering Lupa',
    'Batuk',
    'Tidak Nafsu Makan',
    'Sering Kencing',
    'Kembung',
    'Bingung',
    'Vena Leher Bengkak',
    'Nyeri Dada',
    'Jantung Berdebar',
    'Mual',
    'Muntah',
    'Lain-lainnya',
  ];
  final List<String> _moods = const [
    'Senang',
    'Tenang',
    'Biasa Saja',
    'Lelah',
    'Cemas',
  ];

  Timer? _clockTimer;
  bool _useCurrentTime = true;
  bool _isSavingMetriks = false;
  bool _isSavingGejala = false;
  bool _isSavingAktivitas = false;
  bool _isSavingKonsumsi = false;
  String? _gejalaListError;
  String? _gejalaOtherError;
  String? _gejalaSubmitError;
  String? _metrikFormError;
  String? _metrikHeightError;
  String? _metrikWeightError;
  String? _metrikSystolicError;
  String? _metrikDiastolicError;
  String? _metrikHeartRateError;
  String? _konsumsiTypeError;
  String? _konsumsiNameError;
  String? _konsumsiPortionError;
  String? _konsumsiSubmitError;
  String? _aktivitasSelectionError;
  String? _aktivitasTimeError;
  String? _aktivitasHeartRateError;
  String? _aktivitasFeelingError;
  String? _aktivitasSubmitError;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedMood = 'Biasa Saja';
  int _symptomIntensity = 1;
  final Set<String> _selectedSymptoms = {};
  String _symptomSearchQuery = '';
  String _activitySearchQuery = '';
  String? _selectedConsumptionTypeLabel;
  String? _selectedActivity;
  String? _selectedActivityFeeling;
  TimeOfDay _activityStartTime = TimeOfDay.now();
  TimeOfDay _activityEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  final List<String> _consumptionTypeLabels = const [
    'Snack',
    'Obat',
    'Makanan',
    'Minuman',
  ];
  final List<String> _activityFeelingOptions = const [
    'Lebih baik',
    'Biasa saja',
    'Lelah',
    'Semangat',
  ];

  String _mapConsumptionTypeToApi(String label) {
    switch (label.trim().toLowerCase()) {
      case 'obat':
        return 'medication';
      case 'makanan':
        return 'food';
      case 'minuman':
        return 'drink';
      case 'snack':
      default:
        return 'snack';
    }
  }

  String get _normalizedSectionTitle => widget.title.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _configureSectionLifecycle();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _conditionController.dispose();
    _symptomSearchController.dispose();
    _activitySearchController.dispose();
    _activityHeartRateController.dispose();
    _symptomOtherController.dispose();
    _symptomDescriptionController.dispose();
    _mealNameController.dispose();
    _mealPortionController.dispose();
    _mealDescriptionController.dispose();
    super.dispose();
  }

  void _startLiveClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_useCurrentTime) return;
      setState(() => _selectedTime = TimeOfDay.now());
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE64060),
        ),
      );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _useCurrentTime = false;
        _selectedTime = picked;
      });
    }
  }

  String _conditionTagFromTime(TimeOfDay time) {
    if (time.hour < 12) return 'morning';
    if (time.hour < 17) return 'afternoon';
    return 'evening';
  }

  void _saveKondisi() {
    final conditionText = _conditionController.text.trim();
    if (conditionText.isEmpty) {
      _showValidationError('Mohon isi kondisi terlebih dahulu.');
      return;
    }

    Navigator.of(context).pop({
      'section': widget.title,
      'condition': conditionText,
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
      'mood': _selectedMood,
    });
  }

  Future<void> _saveMetriksKesehatan() async {
    final heightRaw = _heightController.text.trim();
    final weightRaw = _weightController.text.trim();
    final systolicRaw = _systolicController.text.trim();
    final diastolicRaw = _diastolicController.text.trim();
    final heartRateRaw = _heartRateController.text.trim();

    final hasAnyField = heightRaw.isNotEmpty ||
        weightRaw.isNotEmpty ||
        systolicRaw.isNotEmpty ||
        diastolicRaw.isNotEmpty ||
        heartRateRaw.isNotEmpty;

    final heightValue = heightRaw.isEmpty ? null : double.tryParse(heightRaw);
    final weightValue = weightRaw.isEmpty ? null : double.tryParse(weightRaw);
    final systolicValue =
        systolicRaw.isEmpty ? null : int.tryParse(systolicRaw);
    final diastolicValue =
        diastolicRaw.isEmpty ? null : int.tryParse(diastolicRaw);
    final heartRateValue =
        heartRateRaw.isEmpty ? null : int.tryParse(heartRateRaw);

    final hasInvalidNumber = (heightRaw.isNotEmpty && heightValue == null) ||
        (weightRaw.isNotEmpty && weightValue == null) ||
        (systolicRaw.isNotEmpty && systolicValue == null) ||
        (diastolicRaw.isNotEmpty && diastolicValue == null) ||
        (heartRateRaw.isNotEmpty && heartRateValue == null);

    if (!hasAnyField || hasInvalidNumber) {
      setState(() {
        _metrikFormError =
            !hasAnyField ? 'Isi minimal satu data metrik kesehatan.' : null;
        _metrikHeightError = (heightRaw.isNotEmpty && heightValue == null)
            ? 'Tinggi badan harus angka.'
            : null;
        _metrikWeightError = (weightRaw.isNotEmpty && weightValue == null)
            ? 'Berat badan harus angka.'
            : null;
        _metrikSystolicError = (systolicRaw.isNotEmpty && systolicValue == null)
            ? 'Sistolik harus angka.'
            : null;
        _metrikDiastolicError =
            (diastolicRaw.isNotEmpty && diastolicValue == null)
                ? 'Diastolik harus angka.'
                : null;
        _metrikHeartRateError =
            (heartRateRaw.isNotEmpty && heartRateValue == null)
                ? 'Detak jantung harus angka.'
                : null;
      });
      return;
    }

    setState(() {
      _metrikFormError = null;
      _metrikHeightError = null;
      _metrikWeightError = null;
      _metrikSystolicError = null;
      _metrikDiastolicError = null;
      _metrikHeartRateError = null;
    });

    final bodyMassIndex = (heightValue != null &&
            heightValue > 0 &&
            weightValue != null &&
            weightValue > 0)
        ? (weightValue / ((heightValue / 100) * (heightValue / 100)))
        : null;

    final now = DateTime.now();
    final metricsTime = TimeOfDay.fromDateTime(now);

    final payload = {
      'section': widget.title,
      'conditionTag': _conditionTagFromTime(metricsTime),
      'bodyHeight': heightValue,
      'bodyWeight': weightValue,
      'bmi': bodyMassIndex,
      'systolicPressure': systolicValue,
      'diastolicPressure': diastolicValue,
      'heartRate': heartRateValue,
      'timeStamp': now.toUtc().toIso8601String(),
    };

    final submitMetriks = widget.onSubmitMetriks;
    if (submitMetriks == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    setState(() => _isSavingMetriks = true);
    try {
      await submitMetriks(payload);
      if (!mounted) return;
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metrikFormError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingMetriks = false);
      }
    }
  }

  Future<void> _saveGejala() async {
    final needsOther = _selectedSymptoms.contains('Lain-lainnya');
    final hasNoSymptoms = _selectedSymptoms.isEmpty;
    final missingOther =
        needsOther && _symptomOtherController.text.trim().isEmpty;

    if (hasNoSymptoms || missingOther) {
      setState(() {
        _gejalaSubmitError = null;
        _gejalaListError = hasNoSymptoms ? 'Pilih minimal satu gejala.' : null;
        _gejalaOtherError =
            missingOther ? 'Tulis gejala lainnya sebelum menyimpan.' : null;
      });
      return;
    }

    setState(() {
      _gejalaListError = null;
      _gejalaOtherError = null;
      _gejalaSubmitError = null;
    });

    final selectedRaw = _selectedSymptoms.toList();
    final selectedResolved = selectedRaw.map((symptom) {
      if (symptom != 'Lain-lainnya') return symptom;
      final otherText = _symptomOtherController.text.trim();
      return otherText.isEmpty ? 'Lain-lainnya' : otherText;
    }).toList();

    final payload = {
      'section': widget.title,
      'symptoms': selectedResolved,
      'symptomsRaw': selectedRaw,
      'intensity': _symptomIntensity,
      'description': _symptomDescriptionController.text.trim(),
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
    };

    final submitGejala = widget.onSubmitGejala;
    if (submitGejala == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    setState(() => _isSavingGejala = true);
    try {
      await submitGejala(payload);
      if (!mounted) return;
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gejalaSubmitError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingGejala = false);
      }
    }
  }

  Future<void> _saveAktivitas() async {
    final activityName = _selectedActivity?.trim() ?? '';
    final hasInvalidTime =
        _toMinutes(_activityEndTime) <= _toMinutes(_activityStartTime);
    final durationMinutes =
        _toMinutes(_activityEndTime) - _toMinutes(_activityStartTime);
    final heartRate = int.tryParse(_activityHeartRateController.text.trim());
    final feeling = (_selectedActivityFeeling ?? '').trim();

    final missingActivity = activityName.isEmpty;
    final missingHeartRate =
        _activityHeartRateController.text.trim().isEmpty || heartRate == null;
    final missingFeeling = feeling.isEmpty;
    if (missingActivity ||
        hasInvalidTime ||
        missingHeartRate ||
        missingFeeling) {
      setState(() {
        _aktivitasSubmitError = null;
        _aktivitasSelectionError =
            missingActivity ? 'Pilih satu jenis aktivitas.' : null;
        _aktivitasTimeError =
            hasInvalidTime ? 'Waktu selesai harus setelah waktu mulai.' : null;
        _aktivitasHeartRateError = missingHeartRate
            ? 'Masukkan detak jantung rata-rata (angka).'
            : null;
        _aktivitasFeelingError =
            missingFeeling ? 'Pilih perasaan setelah aktivitas.' : null;
      });
      return;
    }

    setState(() {
      _aktivitasSelectionError = null;
      _aktivitasTimeError = null;
      _aktivitasHeartRateError = null;
      _aktivitasFeelingError = null;
      _aktivitasSubmitError = null;
    });

    final payload = {
      'section': widget.title,
      'name': activityName,
      'activity': activityName,
      'duration': durationMinutes,
      'heartRate': heartRate,
      'avgHeartRate': heartRate,
      'userFeeling': feeling,
      'feeling': feeling,
      'startTime': _formatTime(_activityStartTime),
      'endTime': _formatTime(_activityEndTime),
    };

    final submitAktivitas = widget.onSubmitAktivitas;
    if (submitAktivitas == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    setState(() => _isSavingAktivitas = true);
    try {
      await submitAktivitas(payload);
      if (!mounted) return;
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aktivitasSubmitError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingAktivitas = false);
      }
    }
  }

  Future<void> _saveKonsumsi() async {
    final typeLabel = _selectedConsumptionTypeLabel;
    final name = _mealNameController.text.trim();
    final portion = _mealPortionController.text.trim();
    final note = _mealDescriptionController.text.trim();

    final missingType = typeLabel == null || typeLabel.isEmpty;
    final missingName = name.isEmpty;
    final missingPortion = portion.isEmpty;
    if (missingType || missingName || missingPortion) {
      setState(() {
        _konsumsiSubmitError = null;
        _konsumsiTypeError = missingType ? 'Pilih satu tipe konsumsi.' : null;
        _konsumsiNameError = missingName ? 'Mohon isi nama konsumsi.' : null;
        _konsumsiPortionError =
            missingPortion ? 'Mohon isi porsi konsumsi.' : null;
      });
      return;
    }

    setState(() {
      _konsumsiTypeError = null;
      _konsumsiNameError = null;
      _konsumsiPortionError = null;
      _konsumsiSubmitError = null;
    });

    final payload = {
      'section': widget.title,
      'typeLabel': typeLabel,
      'type': _mapConsumptionTypeToApi(typeLabel),
      'name': name,
      'portion': portion,
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
      'note': note,
    };

    final submitKonsumsi = widget.onSubmitKonsumsi;
    if (submitKonsumsi == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    setState(() => _isSavingKonsumsi = true);
    try {
      await submitKonsumsi(payload);
      if (!mounted) return;
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _konsumsiSubmitError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingKonsumsi = false);
      }
    }
  }

  Future<void> _pickActivityTime({required bool isStart}) async {
    final initial = isStart ? _activityStartTime : _activityEndTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _activityStartTime = picked;
      } else {
        _activityEndTime = picked;
      }
    });
  }

  void _configureSectionLifecycle() {
    if (_normalizedSectionTitle == 'metriks kesehatan' ||
        _normalizedSectionTitle == 'kondisi' ||
        _normalizedSectionTitle == 'gejala' ||
        _normalizedSectionTitle.contains('konsumsi')) {
      _startLiveClock();
    }

    if (_normalizedSectionTitle.contains('konsumsi') &&
        _selectedConsumptionTypeLabel == null) {
      _selectedConsumptionTypeLabel = _consumptionTypeLabels.first;
    }

    if (_normalizedSectionTitle.contains('aktivitas') &&
        _selectedActivityFeeling == null) {
      _selectedActivityFeeling = _activityFeelingOptions.first;
    }
  }

  Widget _buildSectionContent() {
    switch (_normalizedSectionTitle) {
      case 'metriks kesehatan':
        return _buildMetriksKesehatanContent();
      case 'kondisi':
        return _buildKondisiContent();
      case 'gejala':
        return _buildGejalaContent();
      case 'aktivitas':
        return _buildAktivitasContent();
      case 'konsumsi':
      case 'konsumsi harian':
        return _buildKonsumsiContent();
      default:
        if (_normalizedSectionTitle.contains('konsumsi')) {
          return _buildKonsumsiContent();
        }
        return const SizedBox(height: 8);
    }
  }

  Widget _buildMetriksKesehatanContent() {
    return AbsorbPointer(
      absorbing: _isSavingMetriks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_metrikFormError != null) ...[
            const SizedBox(height: 10),
            Text(
              _metrikFormError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Tinggi Badan (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_metrikHeightError == null && _metrikFormError == null) {
                return;
              }
              setState(() {
                _metrikHeightError = null;
                _metrikFormError = null;
              });
            },
            style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Contoh: 172.5',
              hintStyle: const TextStyle(color: Color(0x7094A3B8)),
              suffixText: 'cm',
              errorText: _metrikHeightError,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Berat Badan (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_metrikWeightError == null && _metrikFormError == null) {
                return;
              }
              setState(() {
                _metrikWeightError = null;
                _metrikFormError = null;
              });
            },
            style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Contoh: 72',
              hintStyle: const TextStyle(color: Color(0x7094A3B8)),
              suffixText: 'Kg',
              errorText: _metrikWeightError,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tekanan Darah (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _systolicController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_metrikSystolicError == null &&
                        _metrikFormError == null) {
                      return;
                    }
                    setState(() {
                      _metrikSystolicError = null;
                      _metrikFormError = null;
                    });
                  },
                  style:
                      const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Sistolik',
                    suffixText: 'mmHg',
                    errorText: _metrikSystolicError,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE64060)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_metrikDiastolicError == null &&
                        _metrikFormError == null) {
                      return;
                    }
                    setState(() {
                      _metrikDiastolicError = null;
                      _metrikFormError = null;
                    });
                  },
                  style:
                      const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Diastolik',
                    suffixText: 'mmHg',
                    errorText: _metrikDiastolicError,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE64060)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Detak Jantung (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _heartRateController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_metrikHeartRateError == null && _metrikFormError == null) {
                return;
              }
              setState(() {
                _metrikHeartRateError = null;
                _metrikFormError = null;
              });
            },
            style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Contoh: 72',
              hintStyle: const TextStyle(color: Color(0x7094A3B8)),
              suffixText: 'BPM',
              errorText: _metrikHeartRateError,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingMetriks ? null : _saveMetriksKesehatan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSavingMetriks
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKondisiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Tuliskan kondisi mu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _conditionController,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Hari ini badan terasa lebih segar.',
            hintStyle: const TextStyle(
              fontSize: 16,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE64060)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Waktu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _useCurrentTime,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFFE64060),
          title: const Text(
            'Gunakan waktu sekarang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          onChanged: (value) {
            final shouldUseCurrentTime = value ?? false;
            setState(() {
              _useCurrentTime = shouldUseCurrentTime;
              if (shouldUseCurrentTime) {
                _selectedTime = TimeOfDay.now();
              }
            });
          },
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _useCurrentTime ? null : _pickTime,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.access_time),
            label: Text(
              'Pilih Jam (${_formatTime(_selectedTime)})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mood',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _moods
              .map(
                (mood) => ChoiceChip(
                  label: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      mood,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedMood == mood
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  selected: _selectedMood == mood,
                  selectedColor: const Color(0xFFE64060),
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  onSelected: (_) => setState(() => _selectedMood = mood),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveKondisi,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE64060),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGejalaContent() {
    final isOtherSymptom = _selectedSymptoms.contains('Lain-lainnya');
    final filteredSymptoms = _symptomOptions
        .where(
          (item) => item
              .toLowerCase()
              .contains(_symptomSearchQuery.trim().toLowerCase()),
        )
        .toList();

    return AbsorbPointer(
        absorbing: _isSavingGejala,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Waktu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _useCurrentTime,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFE64060),
              title: const Text(
                'Gunakan waktu sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              onChanged: (value) {
                final shouldUseCurrentTime = value ?? false;
                setState(() {
                  _useCurrentTime = shouldUseCurrentTime;
                  if (shouldUseCurrentTime) {
                    _selectedTime = TimeOfDay.now();
                  }
                });
              },
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _useCurrentTime ? null : _pickTime,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.access_time),
                label: Text(
                  'Pilih Jam (${_formatTime(_selectedTime)})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Intensitas Gejala',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _symptomIntensity > 1
                        ? () => setState(() => _symptomIntensity--)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                    icon: const Icon(Icons.remove, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_symptomIntensity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _symptomIntensity < 10
                        ? () => setState(() => _symptomIntensity++)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                    icon: const Icon(Icons.add, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Daftar Gejala',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomSearchController,
              onChanged: (value) {
                setState(() => _symptomSearchQuery = value);
              },
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Cari gejala...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE64060)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _gejalaListError == null
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFE64060),
                ),
              ),
              child: filteredSymptoms.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Gejala tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredSymptoms.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (_, index) {
                        final item = filteredSymptoms[index];
                        final isSelected = _selectedSymptoms.contains(item);
                        return CheckboxListTile(
                          value: isSelected,
                          dense: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFFE64060),
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFFE64060)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedSymptoms.add(item);
                              } else {
                                _selectedSymptoms.remove(item);
                              }
                              _gejalaListError = null;
                              if (!_selectedSymptoms.contains('Lain-lainnya')) {
                                _gejalaOtherError = null;
                              }
                              _gejalaSubmitError = null;
                            });
                          },
                        );
                      },
                    ),
            ),
            if (_gejalaListError != null) ...[
              const SizedBox(height: 8),
              Text(
                _gejalaListError!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE64060),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Gejala Dipilih',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            _selectedSymptoms.isEmpty
                ? const Text(
                    'Belum ada gejala dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSymptoms
                        .map(
                          (symptom) => InputChip(
                            label: Text(
                              symptom,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onDeleted: () {
                              setState(() => _selectedSymptoms.remove(symptom));
                            },
                            deleteIconColor: const Color(0xFFE64060),
                            backgroundColor: const Color(0xFFFDECEF),
                            side: const BorderSide(color: Color(0xFFF8C7D2)),
                          ),
                        )
                        .toList(),
                  ),
            if (isOtherSymptom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _symptomOtherController,
                onChanged: (_) {
                  if (_gejalaOtherError == null && _gejalaSubmitError == null) {
                    return;
                  }
                  setState(() {
                    _gejalaOtherError = null;
                    _gejalaSubmitError = null;
                  });
                },
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Tulis gejala lainnya',
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE64060)),
                  ),
                  errorText: _gejalaOtherError,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Deskripsi Gejala',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomDescriptionController,
              onChanged: (_) {
                if (_gejalaSubmitError == null) return;
                setState(() => _gejalaSubmitError = null);
              },
              minLines: 4,
              maxLines: 6,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Ceritakan gejala yang dirasakan...',
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE64060)),
                ),
              ),
            ),
            if (_gejalaSubmitError != null) ...[
              const SizedBox(height: 10),
              Text(
                _gejalaSubmitError!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE64060),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingGejala ? null : _saveGejala,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE64060),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSavingGejala
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ));
  }

  Widget _buildAktivitasContent() {
    final filteredActivities = _activityOptions
        .where(
          (item) => item
              .toLowerCase()
              .contains(_activitySearchQuery.trim().toLowerCase()),
        )
        .toList();
    final durationMinutes =
        _toMinutes(_activityEndTime) - _toMinutes(_activityStartTime);

    return AbsorbPointer(
      absorbing: _isSavingAktivitas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Waktu Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickActivityTime(isStart: true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'Mulai ${_formatTime(_activityStartTime)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickActivityTime(isStart: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    'Selesai ${_formatTime(_activityEndTime)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_aktivitasTimeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _aktivitasTimeError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              durationMinutes > 0
                  ? 'Durasi otomatis: $durationMinutes menit'
                  : 'Durasi harus lebih dari 0 menit',
              style: TextStyle(
                fontSize: 13,
                color: durationMinutes > 0
                    ? const Color(0xFF2D9744)
                    : const Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Jenis Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _activitySearchController,
            onChanged: (value) => setState(() => _activitySearchQuery = value),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Cari aktivitas...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: filteredActivities.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Aktivitas tidak ditemukan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredActivities.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    itemBuilder: (_, index) {
                      final item = filteredActivities[index];
                      return RadioListTile<String>(
                        value: item,
                        groupValue: _selectedActivity,
                        activeColor: const Color(0xFFE64060),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedActivity == item
                                ? const Color(0xFFE64060)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedActivity = value;
                            _aktivitasSelectionError = null;
                            _aktivitasSubmitError = null;
                          });
                        },
                      );
                    },
                  ),
          ),
          if (_aktivitasSelectionError != null) ...[
            const SizedBox(height: 8),
            Text(
              _aktivitasSelectionError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Aktivitas Dipilih',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          _selectedActivity == null
              ? const Text(
                  'Belum ada aktivitas dipilih',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                )
              : InputChip(
                  label: Text(
                    _selectedActivity!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () {
                    setState(() => _selectedActivity = null);
                  },
                  deleteIconColor: const Color(0xFFE64060),
                  backgroundColor: const Color(0xFFFDECEF),
                  side: const BorderSide(color: Color(0xFFF8C7D2)),
                ),
          const SizedBox(height: 18),
          const Text(
            'Detak Jantung Rata-rata (BPM)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _activityHeartRateController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_aktivitasHeartRateError == null &&
                  _aktivitasSubmitError == null) {
                return;
              }
              setState(() {
                _aktivitasHeartRateError = null;
                _aktivitasSubmitError = null;
              });
            },
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: 98',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
              errorText: _aktivitasHeartRateError,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Perasaan Setelah Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _activityFeelingOptions
                .map(
                  (item) => ChoiceChip(
                    label: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedActivityFeeling == item
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    selected: _selectedActivityFeeling == item,
                    selectedColor: const Color(0xFFE64060),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: BorderSide(
                      color: _aktivitasFeelingError != null &&
                              _selectedActivityFeeling == null
                          ? const Color(0xFFE64060)
                          : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedActivityFeeling = item;
                        _aktivitasFeelingError = null;
                        _aktivitasSubmitError = null;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          if (_aktivitasFeelingError != null) ...[
            const SizedBox(height: 8),
            Text(
              _aktivitasFeelingError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_aktivitasSubmitError != null) ...[
            const SizedBox(height: 10),
            Text(
              _aktivitasSubmitError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingAktivitas ? null : _saveAktivitas,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSavingAktivitas
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKonsumsiContent() {
    return AbsorbPointer(
      absorbing: _isSavingKonsumsi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Waktu Konsumsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _useCurrentTime,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFE64060),
            title: const Text(
              'Gunakan waktu sekarang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            onChanged: (value) {
              final shouldUseCurrentTime = value ?? false;
              setState(() {
                _useCurrentTime = shouldUseCurrentTime;
                if (shouldUseCurrentTime) {
                  _selectedTime = TimeOfDay.now();
                }
              });
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _useCurrentTime ? null : _pickTime,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.access_time),
              label: Text(
                'Pilih Jam (${_formatTime(_selectedTime)})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tipe Konsumsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _consumptionTypeLabels
                .map(
                  (label) => ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedConsumptionTypeLabel == label
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    selected: _selectedConsumptionTypeLabel == label,
                    selectedColor: const Color(0xFFE64060),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: BorderSide(
                      color: _konsumsiTypeError != null &&
                              _selectedConsumptionTypeLabel == null
                          ? const Color(0xFFE64060)
                          : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedConsumptionTypeLabel = label;
                        _konsumsiTypeError = null;
                        _konsumsiSubmitError = null;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          if (_konsumsiTypeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _konsumsiTypeError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Nama Konsumsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mealNameController,
            onChanged: (_) {
              if (_konsumsiNameError == null && _konsumsiSubmitError == null) {
                return;
              }
              setState(() {
                _konsumsiNameError = null;
                _konsumsiSubmitError = null;
              });
            },
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Aspirin',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
              errorText: _konsumsiNameError,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Porsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mealPortionController,
            onChanged: (_) {
              if (_konsumsiPortionError == null &&
                  _konsumsiSubmitError == null) {
                return;
              }
              setState(() {
                _konsumsiPortionError = null;
                _konsumsiSubmitError = null;
              });
            },
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: 1 tablet',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
              errorText: _konsumsiPortionError,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Catatan (Opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mealDescriptionController,
            onChanged: (_) {
              if (_konsumsiSubmitError == null) return;
              setState(() => _konsumsiSubmitError = null);
            },
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Sesudah makan malam',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
          ),
          if (_konsumsiSubmitError != null) ...[
            const SizedBox(height: 10),
            Text(
              _konsumsiSubmitError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingKonsumsi ? null : _saveKonsumsi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSavingKonsumsi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionContent(),
            ],
          ),
        ),
      ),
    );
  }
}
