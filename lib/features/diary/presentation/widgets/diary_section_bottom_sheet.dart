import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_consumption_result.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';
import 'package:pulsewise/features/food_analysis/presentation/pages/food_macro_camera_page.dart';
import 'package:pulsewise/features/food_analysis/presentation/pages/manual_food_macro_entry_page.dart';

typedef GejalaSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef KonsumsiSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef AktivitasSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef MetriksSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);
typedef TidurSubmitCallback = Future<void> Function(
    Map<String, dynamic> payload);

class DiarySectionBottomSheet extends StatefulWidget {
  final String title;
  final ScrollController? scrollController;
  final GejalaSubmitCallback? onSubmitGejala;
  final KonsumsiSubmitCallback? onSubmitKonsumsi;
  final AktivitasSubmitCallback? onSubmitAktivitas;
  final MetriksSubmitCallback? onSubmitMetriks;
  final TidurSubmitCallback? onSubmitTidur;

  const DiarySectionBottomSheet({
    super.key,
    required this.title,
    this.scrollController,
    this.onSubmitGejala,
    this.onSubmitKonsumsi,
    this.onSubmitAktivitas,
    this.onSubmitMetriks,
    this.onSubmitTidur,
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
  final TextEditingController _oxygenController = TextEditingController();
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

  final List<Map<String, dynamic>> _symptomOptions = const [
    {'name': 'Sulit Bernafas', 'code': 'shortness_of_breath', 'area': 'chest'},
    {'name': 'Kaki Bengkak', 'code': 'swelling', 'area': 'leg'},
    {'name': 'Lemas', 'code': 'fatigue', 'area': 'general'},
    {'name': 'Sulit Tidur', 'code': 'other', 'area': 'head'},
    {'name': 'Perut Bengkak', 'code': 'swelling', 'area': 'upper_abdomen'},
    {'name': 'Sering Lupa', 'code': 'other', 'area': 'head'},
    {'name': 'Batuk', 'code': 'cough', 'area': 'chest'},
    {'name': 'Tidak Nafsu Makan', 'code': 'other', 'area': 'general'},
    {'name': 'Sering Kencing', 'code': 'other', 'area': 'general'},
    {'name': 'Kembung', 'code': 'other', 'area': 'upper_abdomen'},
    {'name': 'Bingung', 'code': 'dizziness', 'area': 'head'},
    {'name': 'Vena Leher Bengkak', 'code': 'swelling', 'area': 'neck'},
    {'name': 'Nyeri Dada', 'code': 'chest_pain', 'area': 'chest'},
    {'name': 'Jantung Berdebar', 'code': 'palpitations', 'area': 'chest'},
    {'name': 'Mual', 'code': 'nausea', 'area': 'upper_abdomen'},
    {'name': 'Muntah', 'code': 'other', 'area': 'upper_abdomen'},
    {'name': 'Sakit Kepala', 'code': 'headache', 'area': 'head'},
    {'name': 'Lain-lainnya', 'code': 'other', 'area': 'general'},
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
  bool _isManualSimpleExpanded = false;
  String? _gejalaListError;
  String? _gejalaOtherError;
  String? _gejalaSubmitError;
  String? _metrikFormError;
  String? _metrikHeightError;
  String? _metrikWeightError;
  String? _metrikSystolicError;
  String? _metrikDiastolicError;
  String? _metrikHeartRateError;
  String? _metrikOxygenError;
  String? _konsumsiTypeError;
  String? _konsumsiNameError;
  String? _konsumsiPortionError;
  String? _konsumsiSubmitError;
  String? _aktivitasSelectionError;
  String? _aktivitasTimeError;
  String? _aktivitasHeartRateError;
  String? _aktivitasFeelingError;
  String? _aktivitasOutdoorError;
  String? _aktivitasSubmitError;
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  bool _isSavingTidur = false;
  String? _tidurSubmitError;
  String _selectedMood = 'Biasa Saja';
  int _symptomIntensity = 5;
  int? _painFrequencyCode;
  int? _painLocationCode;
  final Set<String> _selectedSymptoms = {};
  String _symptomSearchQuery = '';
  String _activitySearchQuery = '';
  String? _selectedConsumptionTypeLabel;
  String? _selectedActivity;
  String? _selectedActivityFeeling;
  FoodMacroAnalysis? _foodMacroAnalysis;

  // NEW ML ACTIVITY FIELDS
  String _activityCategory = 'recreation';
  String? _intensityLevel;
  String? _transportMode;
  final TextEditingController _outdoorMinutesController =
      TextEditingController();
  final TextEditingController _activityNoteController = TextEditingController();

  TimeOfDay _activityStartTime = TimeOfDay.now();
  TimeOfDay _activityEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  final List<String> _consumptionTypeLabels = const [
    'Makanan Berat',
    'Makanan Ringan',
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
      case 'makanan berat':
      case 'breakfast':
      case 'sarapan':
      case 'lunch':
      case 'makan siang':
      case 'dinner':
      case 'makan malam':
      case 'makanan':
      case 'food':
        return 'Makanan Berat';
      case 'makanan ringan':
      case 'snack':
      case 'cemilan':
      case 'camilan':
      case 'other':
      case 'lainnya':
      case 'medication':
      case 'obat':
        return 'Makanan Ringan';
      case 'drink':
      case 'minuman':
        return 'Minuman';
      default:
        return 'Makanan Berat';
    }
  }

  String _formatConsumptionTypeLabel(String value) {
    switch (_mapConsumptionTypeToApi(value)) {
      case 'Makanan Ringan':
        return 'Makanan Ringan';
      case 'Minuman':
        return 'Minuman';
      case 'Makanan Berat':
      default:
        return 'Makanan Berat';
    }
  }

  String _resolveFoodAnalysisPortion(FoodMacroAnalysis analysis) {
    if (analysis.portionEstimate.isNotEmpty) {
      return FoodMacroAnalysis.truncatePortionText(analysis.portionEstimate);
    }

    if (analysis.portionGramsEstimate > 0) {
      return '${analysis.portionGramsEstimate.round()} g';
    }

    return '1 porsi';
  }

  String _buildFoodAnalysisNote(FoodMacroCaptureResult result) {
    final analysisNotes = result.analysis.notes.trim();
    final noteParts = <String>[
      if (result.userDescription.isNotEmpty) result.userDescription,
      if (analysisNotes.isNotEmpty) 'Analisis foto: $analysisNotes',
    ];
    return noteParts.join('\n\n');
  }

  Map<String, dynamic> _buildFoodAnalysisConsumptionPayload(
    FoodMacroCaptureResult result,
  ) {
    final analysis = result.analysis;
    final suggestedName = analysis.suggestedName.trim();
    final resolvedName = result.userFoodName.isNotEmpty
        ? result.userFoodName
        : (suggestedName.isNotEmpty ? suggestedName : 'Makanan');

    return {
      'section': widget.title,
      'typeLabel': _formatConsumptionTypeLabel(analysis.mealCategory),
      'type': _mapConsumptionTypeToApi(analysis.mealCategory),
      'name': resolvedName,
      'portion': _resolveFoodAnalysisPortion(analysis),
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
      'note': _buildFoodAnalysisNote(result),
      'foodMacroAnalysis': analysis.toJson(),
      'nutritionPayload': analysis.toNutritionPayload(),
    };
  }

  Future<void> _runKonsumsiSubmission(Map<String, dynamic> payload) async {
    final submitKonsumsi = widget.onSubmitKonsumsi;
    if (submitKonsumsi == null) return;

    setState(() => _isSavingKonsumsi = true);
    try {
      await submitKonsumsi(payload);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _konsumsiSubmitError = e.toString().replaceFirst('Exception: ', '');
      });
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isSavingKonsumsi = false);
      }
    }
  }

  Future<void> _submitKonsumsiPayload(Map<String, dynamic> payload) async {
    final submitKonsumsi = widget.onSubmitKonsumsi;
    if (submitKonsumsi == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    await _runKonsumsiSubmission(payload);
    if (!mounted) return;
    Navigator.of(context).pop({
      'section': widget.title,
      'saved': true,
    });
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
    _oxygenController.dispose();
    _conditionController.dispose();
    _symptomSearchController.dispose();
    _activitySearchController.dispose();
    _activityHeartRateController.dispose();
    _symptomOtherController.dispose();
    _symptomDescriptionController.dispose();
    _mealNameController.dispose();
    _mealPortionController.dispose();
    _mealDescriptionController.dispose();
    _outdoorMinutesController.dispose();
    _activityNoteController.dispose();
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
    final oxygenRaw = _oxygenController.text.trim();

    final hasAnyField = heightRaw.isNotEmpty ||
        weightRaw.isNotEmpty ||
        systolicRaw.isNotEmpty ||
        diastolicRaw.isNotEmpty ||
        heartRateRaw.isNotEmpty ||
        oxygenRaw.isNotEmpty;

    final heightValue = heightRaw.isEmpty ? null : double.tryParse(heightRaw);
    final weightValue = weightRaw.isEmpty ? null : double.tryParse(weightRaw);
    final systolicValue =
        systolicRaw.isEmpty ? null : int.tryParse(systolicRaw);
    final diastolicValue =
        diastolicRaw.isEmpty ? null : int.tryParse(diastolicRaw);
    final heartRateValue =
        heartRateRaw.isEmpty ? null : int.tryParse(heartRateRaw);
    final oxygenValue = oxygenRaw.isEmpty ? null : int.tryParse(oxygenRaw);

    final hasInvalidNumber = (heightRaw.isNotEmpty && heightValue == null) ||
        (weightRaw.isNotEmpty && weightValue == null) ||
        (systolicRaw.isNotEmpty && systolicValue == null) ||
        (diastolicRaw.isNotEmpty && diastolicValue == null) ||
        (heartRateRaw.isNotEmpty && heartRateValue == null) ||
        (oxygenRaw.isNotEmpty && oxygenValue == null);

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
        _metrikOxygenError = (oxygenRaw.isNotEmpty && oxygenValue == null)
            ? 'Saturasi Oksigen harus angka.'
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
      _metrikOxygenError = null;
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
      'oxygenSaturation': oxygenValue,
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
    final isChestPain = _selectedSymptoms.contains('Nyeri Dada');
    final missingOther =
        needsOther && _symptomOtherController.text.trim().isEmpty;
    final missingChestPainDetails = isChestPain &&
        (_painFrequencyCode == null || _painLocationCode == null);

    if (hasNoSymptoms || missingOther || missingChestPainDetails) {
      setState(() {
        _gejalaSubmitError = null;
        _gejalaListError = hasNoSymptoms ? 'Pilih minimal satu gejala.' : null;
        _gejalaOtherError =
            missingOther ? 'Tulis gejala lainnya sebelum menyimpan.' : null;
        if (missingChestPainDetails) {
          _gejalaListError =
              'Lengkapi detail lama sakit dan area untuk Nyeri Dada.';
        }
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

    final symptomsMapped = selectedResolved.map((symptomName) {
      final originalName = symptomName == _symptomOtherController.text.trim() &&
              symptomName.isNotEmpty
          ? 'Lain-lainnya'
          : symptomName;
      final meta = _symptomOptions.firstWhere(
        (e) => e['name'] == originalName,
        orElse: () => {'name': symptomName, 'code': 'other', 'area': 'general'},
      );
      final isThisChestPain = meta['code'] == 'chest_pain';

      return {
        'symptomName': symptomName,
        'symptomCode': meta['code'],
        'bodyArea': meta['area'],
        'isChestPain': isThisChestPain,
        'painFrequencyCode': isThisChestPain ? _painFrequencyCode : null,
        'painLocationCode': isThisChestPain ? _painLocationCode : null,
      };
    }).toList();

    final payload = {
      'section': widget.title,
      'symptoms': selectedResolved,
      'symptomsRaw': selectedRaw,
      'symptomsMapped': symptomsMapped,
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
    var durationMinutes =
        _toMinutes(_activityEndTime) - _toMinutes(_activityStartTime);
    if (durationMinutes < 0) durationMinutes += 24 * 60; // Handle overnight

    final hasInvalidTime = durationMinutes <= 0;

    final heartRateText = _activityHeartRateController.text.trim();
    final heartRate =
        heartRateText.isNotEmpty ? int.tryParse(heartRateText) : null;

    final feeling = (_selectedActivityFeeling ?? '').trim();

    final outdoorMinsText = _outdoorMinutesController.text.trim();
    final outdoorMinutes =
        outdoorMinsText.isNotEmpty ? int.tryParse(outdoorMinsText) : null;

    final missingActivity = activityName.isEmpty;
    final missingOutdoor = outdoorMinsText.isEmpty || outdoorMinutes == null;

    if (missingActivity || hasInvalidTime || missingOutdoor) {
      setState(() {
        _aktivitasSubmitError = null;
        _aktivitasSelectionError =
            missingActivity ? 'Pilih satu jenis aktivitas.' : null;
        _aktivitasTimeError =
            hasInvalidTime ? 'Waktu selesai tidak valid.' : null;
        _aktivitasOutdoorError =
            missingOutdoor ? 'Masukkan durasi di luar ruangan (angka)' : null;
      });
      return;
    }

    setState(() {
      _aktivitasSelectionError = null;
      _aktivitasTimeError = null;
      _aktivitasOutdoorError = null;
      _aktivitasHeartRateError = null;
      _aktivitasFeelingError = null;
      _aktivitasSubmitError = null;
    });

    final payload = {
      'section': widget.title,
      'name': activityName,
      'activityCategory': _activityCategory,
      'intensityLevel': _intensityLevel,
      'transportMode': _activityCategory == 'transport' ? _transportMode : null,
      'outdoorMinutes': outdoorMinutes,
      'duration': durationMinutes,
      'heartRate': heartRate,
      'userFeeling': feeling,
      'note': _activityNoteController.text.trim(),
      'startTime':
          '${_activityStartTime.hour.toString().padLeft(2, '0')}:${_activityStartTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${_activityEndTime.hour.toString().padLeft(2, '0')}:${_activityEndTime.minute.toString().padLeft(2, '0')}',
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
    final portionTooLong =
        portion.length > FoodMacroAnalysis.maxPortionEstimateLength;
    if (missingType || missingName || missingPortion || portionTooLong) {
      setState(() {
        _konsumsiSubmitError = null;
        _konsumsiTypeError =
            missingType ? 'Pilih satu kategori konsumsi.' : null;
        _konsumsiNameError = missingName ? 'Mohon isi nama konsumsi.' : null;
        _konsumsiPortionError = missingPortion
            ? 'Mohon isi porsi konsumsi.'
            : portionTooLong
                ? 'Porsi maksimal ${FoodMacroAnalysis.maxPortionEstimateLength} karakter.'
                : null;
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
      'foodMacroAnalysis': _foodMacroAnalysis?.toJson(),
      'nutritionPayload': _foodMacroAnalysis?.toNutritionPayload(),
    };
    await _submitKonsumsiPayload(payload);
  }

  Future<void> _openFoodMacroCameraPage() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FoodMacroCameraPage(
          onUseAnalysis: (captureResult) async {
            await _runKonsumsiSubmission(
              _buildFoodAnalysisConsumptionPayload(captureResult),
            );
          },
        ),
      ),
    );

    if (!mounted || result == null) return;

    final action = (result['action'] ?? '').toString();
    if (action == 'saved') {
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
      return;
    }

    final captureResult = FoodMacroCaptureResult.fromMap(result);
    final userFoodName = captureResult.userFoodName;
    final userDescription = captureResult.userDescription;
    final analysis = captureResult.analysis;
    final suggestedName = analysis.suggestedName;
    final analysisNotes = analysis.notes.trim();
    final existingNote = _mealDescriptionController.text.trim();
    final noteParts = <String>[
      if (existingNote.isNotEmpty) existingNote,
      if (userDescription.isNotEmpty) userDescription,
      if (analysisNotes.isNotEmpty) 'Analisis foto: $analysisNotes',
    ];

    setState(() {
      _foodMacroAnalysis = analysis;
      _selectedConsumptionTypeLabel =
          _formatConsumptionTypeLabel(analysis.mealCategory);
      _isManualSimpleExpanded = true;
      if (userFoodName.isNotEmpty) {
        _mealNameController.text = userFoodName;
      } else if (suggestedName.isNotEmpty) {
        _mealNameController.text = suggestedName;
      }
      if (analysis.portionEstimate.isNotEmpty) {
        _mealPortionController.text =
            FoodMacroAnalysis.truncatePortionText(analysis.portionEstimate);
      }
      if (noteParts.isNotEmpty) {
        _mealDescriptionController.text = noteParts.join('\n\n');
      }
      _konsumsiTypeError = null;
      _konsumsiNameError = null;
      _konsumsiPortionError = null;
      _konsumsiSubmitError = null;
    });
  }

  Future<void> _openManualMacroEntryPage() async {
    final selectedTypeLabel = (_selectedConsumptionTypeLabel == null ||
            _selectedConsumptionTypeLabel!.trim().isEmpty)
        ? _consumptionTypeLabels.first
        : _selectedConsumptionTypeLabel!;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ManualFoodMacroEntryPage(
          onSubmitConsumption: (manualResult) async {
            await _runKonsumsiSubmission({
              'section': widget.title,
              ...manualResult.toMap(),
            });
          },
          consumptionTypeLabel: _formatConsumptionTypeLabel(selectedTypeLabel),
          consumptionTypeApi: _mapConsumptionTypeToApi(selectedTypeLabel),
          consumptionTime: _formatTime(_selectedTime),
          useCurrentTime: _useCurrentTime,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final action = (result['action'] ?? '').toString();
    if (action == 'saved') {
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
      return;
    }

    Navigator.of(context).pop({
      'section': widget.title,
      ...result,
    });
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

  Future<void> _pickTidurTime({required bool isStart}) async {
    final initial = isStart ? _sleepTime : _wakeTime;
    final picked = await showTimePicker(
      context: context,
      barrierColor: Colors.white,
      initialTime: initial,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _sleepTime = picked;
      } else {
        _wakeTime = picked;
      }
    });
  }

  Future<void> _saveTidur() async {
    var durationMinutes = _toMinutes(_wakeTime) - _toMinutes(_sleepTime);
    if (durationMinutes < 0) durationMinutes += 24 * 60; // Handle overnight

    if (durationMinutes <= 0) {
      setState(() {
        _tidurSubmitError = 'Durasi tidur tidak valid.';
      });
      return;
    }

    setState(() {
      _tidurSubmitError = null;
    });

    final payload = {
      'section': widget.title,
      'sleepTime': _formatTime(_sleepTime),
      'wakeTime': _formatTime(_wakeTime),
      'duration': durationMinutes / 60.0,
    };

    final submitTidur = widget.onSubmitTidur;
    if (submitTidur == null) {
      Navigator.of(context).pop(payload);
      return;
    }

    setState(() => _isSavingTidur = true);
    try {
      await submitTidur(payload);
      if (!mounted) return;
      Navigator.of(context).pop({
        'section': widget.title,
        'saved': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tidurSubmitError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingTidur = false);
      }
    }
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
      case 'tidur':
        return _buildTidurSection();
      default:
        if (_normalizedSectionTitle.contains('konsumsi')) {
          return _buildKonsumsiContent();
        }
        return const SizedBox(height: 8);
    }
  }

  Widget _buildTidurSection() {
    var durationMinutes = _toMinutes(_wakeTime) - _toMinutes(_sleepTime);
    if (durationMinutes < 0) durationMinutes += 24 * 60; // Handle overnight

    return AbsorbPointer(
      absorbing: _isSavingTidur,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Catat Jam Tidur Anda',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waktu Tidur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTidurTime(isStart: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon:
                            const Icon(Icons.bedtime, color: Color(0xFF3B82F6)),
                        label: Text(
                          _formatTime(_sleepTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waktu Bangun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTidurTime(isStart: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.wb_sunny,
                            color: Color(0xFFF59E0B)),
                        label: Text(
                          _formatTime(_wakeTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFF64748B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total Durasi Tidur: ${durationMinutes ~/ 60} jam ${durationMinutes % 60} menit',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_tidurSubmitError != null) ...[
            const SizedBox(height: 16),
            Text(
              _tidurSubmitError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE64060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingTidur ? null : _saveTidur,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSavingTidur
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan Data Tidur',
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
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
          const SizedBox(height: 18),
          const Text(
            'Saturasi Oksigen (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _oxygenController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_metrikOxygenError == null && _metrikFormError == null) {
                return;
              }
              setState(() {
                _metrikOxygenError = null;
                _metrikFormError = null;
              });
            },
            style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Contoh: 98',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              suffixText: '%',
              errorText: _metrikOxygenError,
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
    final isChestPain = _selectedSymptoms.contains('Nyeri Dada');
    final filteredSymptoms = _symptomOptions
        .where(
          (item) => (item['name'] as String)
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
              padding:
                  const EdgeInsets.only(top: 10, bottom: 2, left: 0, right: 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_symptomIntensity ${_symptomIntensity <= 3 ? '(Ringan)' : _symptomIntensity <= 6 ? '(Sedang)' : '(Berat)'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Slider(
                    value: _symptomIntensity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _symptomIntensity.toString(),
                    activeColor: const Color(0xFFE64060),
                    inactiveColor: const Color(0xFFFDECEF),
                    onChanged: (value) {
                      setState(() {
                        _symptomIntensity = value.toInt();
                      });
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600)),
                        Text('10',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        final itemName = item['name'] as String;
                        final isSelected = _selectedSymptoms.contains(itemName);
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
                            itemName,
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
                                _selectedSymptoms.add(itemName);
                              } else {
                                _selectedSymptoms.remove(itemName);
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
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            _selectedSymptoms.isEmpty
                ? const Text(
                    'Belum ada gejala dipilih',
                    style: TextStyle(
                      fontSize: 16,
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
                                fontSize: 16,
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
            if (isChestPain) ...[
              const SizedBox(height: 16),
              const Text(
                'Berapa lama nyeri dada?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    dropdownColor: Colors.white,
                    value: _painFrequencyCode,
                    hint: const Text(
                      'Pilih durasi nyeri',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 0, child: Text('Tidak tahu / tidak yakin')),
                      DropdownMenuItem(
                          value: 1, child: Text('Kurang dari 30 menit')),
                      DropdownMenuItem(
                          value: 2, child: Text('30 menit atau lebih')),
                    ],
                    onChanged: (value) => setState(() {
                      _painFrequencyCode = value;
                      _gejalaListError = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Di area mana nyeri terasa dominan?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    dropdownColor: Colors.white,
                    value: _painLocationCode,
                    hint: const Text(
                      'Pilih lokasi nyeri',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 0, child: Text('Tidak tahu / tidak yakin')),
                      DropdownMenuItem(value: 1, child: Text('Lengan kanan')),
                      DropdownMenuItem(value: 2, child: Text('Dada kanan')),
                      DropdownMenuItem(value: 3, child: Text('Leher')),
                      DropdownMenuItem(
                          value: 4,
                          child: Text('Dada atas / tulang dada atas')),
                      DropdownMenuItem(
                          value: 5,
                          child: Text('Dada bawah / tulang dada bawah')),
                      DropdownMenuItem(value: 6, child: Text('Dada kiri')),
                      DropdownMenuItem(value: 7, child: Text('Lengan kiri')),
                      DropdownMenuItem(
                          value: 8, child: Text('Ulu hati / perut atas')),
                    ],
                    onChanged: (value) => setState(() {
                      _painLocationCode = value;
                      _gejalaListError = null;
                    }),
                  ),
                ),
              ),
            ],
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
    var durationMinutes =
        _toMinutes(_activityEndTime) - _toMinutes(_activityStartTime);
    if (durationMinutes < 0) durationMinutes += 24 * 60;

    return AbsorbPointer(
      absorbing: _isSavingAktivitas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kategori Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            value: _activityCategory,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'work', child: Text('Pekerjaan (Work)')),
              DropdownMenuItem(
                  value: 'transport', child: Text('Transportasi (Transport)')),
              DropdownMenuItem(
                  value: 'recreation',
                  child: Text('Rekreasi / Olahraga (Recreation)')),
              DropdownMenuItem(
                  value: 'other', child: Text('Lain-lain (Other)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _activityCategory = val;
                  if (val != 'work' && val != 'recreation') {
                    _intensityLevel = null;
                  }
                  if (val != 'transport') {
                    _transportMode = null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          if (_activityCategory == 'work' ||
              _activityCategory == 'recreation') ...[
            const Text(
              'Intensitas Aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: _intensityLevel,
              hint: const Text(
                'Pilih Intensitas',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Ringan (Light)')),
                DropdownMenuItem(
                    value: 'moderate', child: Text('Sedang (Moderate)')),
                DropdownMenuItem(
                    value: 'vigorous', child: Text('Berat/Kuat (Vigorous)')),
                DropdownMenuItem(
                    value: 'unknown', child: Text('Tidak Yakin / Lainnya')),
              ],
              onChanged: (val) => setState(() => _intensityLevel = val),
            ),
            const SizedBox(height: 16),
          ],
          if (_activityCategory == 'transport') ...[
            const Text(
              'Mode Transportasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: _transportMode,
              hint: const Text(
                'Pilih Mode',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'walk', child: Text('Berjalan Kaki (Walk)')),
                DropdownMenuItem(
                    value: 'bicycle', child: Text('Bersepeda (Bicycle)')),
                DropdownMenuItem(
                    value: 'other', child: Text('Kendaraan / Lainnya')),
              ],
              onChanged: (val) => setState(() => _transportMode = val),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Nama Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
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
              fontSize: 18,
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
          const SizedBox(height: 20),
          const Text(
            'Durasi di Luar Ruangan (Menit)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _outdoorMinutesController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_aktivitasOutdoorError == null &&
                  _aktivitasSubmitError == null) {
                return;
              }
              setState(() {
                _aktivitasOutdoorError = null;
                _aktivitasSubmitError = null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Dalam menit (misal: 15)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE64060))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              errorText: _aktivitasOutdoorError,
            ),
          ),
          // const SizedBox(height: 18),
          // const Text(
          //   'Detak Jantung Rata-rata (BPM)',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //     color: Color(0xFF334155),
          //   ),
          // ),
          // const SizedBox(height: 10),
          // TextField(
          //   controller: _activitySearchController,
          //   onChanged: (value) => setState(() => _activitySearchQuery = value),
          //   style: const TextStyle(
          //     fontSize: 16,
          //     color: Color(0xFF0F172A),
          //   ),
          //   decoration: InputDecoration(
          //     hintText: 'Cari aktivitas...',
          //     prefixIcon: const Icon(Icons.search),
          //     filled: true,
          //     fillColor: const Color(0xFFF8FAFC),
          //     contentPadding:
          //         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(14),
          //       borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          //     ),
          //     enabledBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(14),
          //       borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          //     ),
          //     focusedBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(14),
          //       borderSide: const BorderSide(color: Color(0xFFE64060)),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 10),
          // Container(
          //   constraints: const BoxConstraints(maxHeight: 260),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF8FAFC),
          //     borderRadius: BorderRadius.circular(14),
          //     border: Border.all(color: const Color(0xFFE2E8F0)),
          //   ),
          //   child: filteredActivities.isEmpty
          //       ? const Center(
          //           child: Padding(
          //             padding: EdgeInsets.symmetric(vertical: 20),
          //             child: Text(
          //               'Aktivitas tidak ditemukan',
          //               style: TextStyle(
          //                 fontSize: 16,
          //                 color: Color(0xFF64748B),
          //               ),
          //             ),
          //           ),
          //         )
          //       : ListView.separated(
          //           shrinkWrap: true,
          //           padding: const EdgeInsets.symmetric(vertical: 4),
          //           itemCount: filteredActivities.length,
          //           separatorBuilder: (_, __) => const Divider(
          //             height: 1,
          //             color: Color(0xFFE2E8F0),
          //           ),
          //           itemBuilder: (_, index) {
          //             final item = filteredActivities[index];
          //             return RadioListTile<String>(
          //               value: item,
          //               groupValue: _selectedActivity,
          //               activeColor: const Color(0xFFE64060),
          //               contentPadding: const EdgeInsets.symmetric(
          //                 horizontal: 8,
          //                 vertical: 0,
          //               ),
          //               title: Text(
          //                 item,
          //                 style: TextStyle(
          //                   fontSize: 16,
          //                   fontWeight: FontWeight.w600,
          //                   color: _selectedActivity == item
          //                       ? const Color(0xFFE64060)
          //                       : const Color(0xFF0F172A),
          //                 ),
          //               ),
          //               onChanged: (value) {
          //                 setState(() {
          //                   _selectedActivity = value;
          //                   _aktivitasSelectionError = null;
          //                   _aktivitasSubmitError = null;
          //                 });
          //               },
          //             );
          //           },
          //         ),
          // ),
          // if (_aktivitasSelectionError != null) ...[
          //   const SizedBox(height: 8),
          //   Text(
          //     _aktivitasSelectionError!,
          //     style: const TextStyle(
          //       fontSize: 13,
          //       color: Color(0xFFE64060),
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          // ],
          // const SizedBox(height: 12),
          // const Text(
          //   'Aktivitas Dipilih',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w700,
          //     color: Color(0xFF334155),
          //   ),
          // ),
          // const SizedBox(height: 8),
          // _selectedActivity == null
          //     ? const Text(
          //         'Belum ada aktivitas dipilih',
          //         style: TextStyle(
          //           fontSize: 14,
          //           color: Color(0xFF64748B),
          //         ),
          //       )
          //     : InputChip(
          //         label: Text(
          //           _selectedActivity!,
          //           style: const TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //         onDeleted: () {
          //           setState(() => _selectedActivity = null);
          //         },
          //         deleteIconColor: const Color(0xFFE64060),
          //         backgroundColor: const Color(0xFFFDECEF),
          //         side: const BorderSide(color: Color(0xFFF8C7D2)),
          //       ),
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
              fontWeight: FontWeight.bold,
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
                        fontSize: 16,
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
          const SizedBox(height: 18),
          const Text(
            'Catatan Tambahan (opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _activityNoteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan detail lainnya...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
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

  Widget _buildKonsumsiTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  Widget _buildKonsumsiMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Cara Input',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silakan pilih cara yang paling mudah untuk mencatat konsumsi hari ini.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _ConsumptionMethodCard(
          icon: Icons.camera_alt_rounded,
          iconColor: const Color(0xFF9A3412),
          iconBackgroundColor: const Color(0xFFFFEDD5),
          borderColor: const Color(0xFFFED7AA),
          title: 'Analisis Foto Makanan / Minuman',
          description:
              'Ambil foto. Sistem akan membantu memperkirakan kategori konsumsi dan nutrisi.',
          actionLabel: 'Buka kamera',
          actionIcon: Icons.arrow_forward_rounded,
          onPressed: _openFoodMacroCameraPage,
        ),
        const SizedBox(height: 12),
        _ConsumptionMethodCard(
          icon: Icons.analytics_outlined,
          iconColor: const Color(0xFF1D4ED8),
          iconBackgroundColor: const Color(0xFFDBEAFE),
          borderColor: const Color(0xFFBFDBFE),
          title: 'Input Nutrisi Lengkap',
          description:
              'Isi manual kalori, protein, lemak, serat, dan data nutrisi lainnya bila tersedia.',
          actionLabel: 'Isi lengkap',
          actionIcon: Icons.open_in_new_rounded,
          onPressed: _openManualMacroEntryPage,
        ),
        const SizedBox(height: 12),
        _ConsumptionMethodCard(
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFF047857),
          iconBackgroundColor: const Color(0xFFECFDF3),
          borderColor: const Color(0xFFA7F3D0),
          title: 'Input Manual Sederhana',
          description:
              'Isi kategori, nama konsumsi, porsi, dan catatan tanpa data nutrisi detail.',
          badgeLabel: _isManualSimpleExpanded ? 'Form sedang terbuka' : null,
          badgeBackgroundColor: const Color(0xFFD1FAE5),
          badgeTextColor: const Color(0xFF065F46),
          actionLabel:
              _isManualSimpleExpanded ? 'Sembunyikan form' : 'Buka form',
          actionIcon: _isManualSimpleExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          onPressed: () {
            setState(() {
              _isManualSimpleExpanded = !_isManualSimpleExpanded;
            });
          },
        ),
        if (_foodMacroAnalysis != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Analisis Foto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 10),
                _FoodMacroSummaryCard(analysis: _foodMacroAnalysis!),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKonsumsiCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Konsumsi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bagian ini dipakai untuk input manual. Jika memakai foto, kategori mengikuti hasil analisis.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            height: 1.45,
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
                    _formatConsumptionTypeLabel(label),
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
                  onSelected: _foodMacroAnalysis != null
                      ? null
                      : (_) {
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
        if (_foodMacroAnalysis != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Kategori dari hasil analisis foto sudah terkunci dan tidak bisa diubah manual.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9A3412),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
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
      ],
    );
  }

  Widget _buildKonsumsiManualForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input Manual Sederhana',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cocok untuk catatan cepat ketika Anda belum ingin mengisi nutrisi detail.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
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
              hintText: 'Contoh: nasi tim ayam, teh hangat, pisang rebus',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                FoodMacroAnalysis.maxPortionEstimateLength,
              ),
            ],
            maxLength: FoodMacroAnalysis.maxPortionEstimateLength,
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
              hintText: 'Contoh: 1 mangkuk kecil, 1 gelas, 2 potong',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
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
              hintText:
                  'Contoh: tanpa gula, kuah sedikit, dimakan setelah jalan pagi',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
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
                      'Simpan Konsumsi',
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

  Widget _buildExpandableKonsumsiManualSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: !_isManualSimpleExpanded
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                _buildKonsumsiCategorySection(),
                const SizedBox(height: 18),
                _buildKonsumsiManualForm(),
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
          _buildKonsumsiTimeSection(),
          const SizedBox(height: 22),
          _buildKonsumsiMethodSection(),
          _buildExpandableKonsumsiManualSection(),
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

class _ConsumptionMethodCard extends StatelessWidget {
  const _ConsumptionMethodCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.borderColor,
    required this.title,
    required this.description,
    this.badgeLabel,
    this.badgeBackgroundColor,
    this.badgeTextColor,
    this.actionLabel,
    this.actionIcon,
    this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color borderColor;
  final String title;
  final String description;
  final String? badgeLabel;
  final Color? badgeBackgroundColor;
  final Color? badgeTextColor;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onPressed != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // if (badgeLabel != null) ...[
          //   const SizedBox(height: 12),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: badgeBackgroundColor ?? const Color(0xFFF1F5F9),
          //       borderRadius: BorderRadius.circular(999),
          //     ),
          //     child: Text(
          //       badgeLabel!,
          //       style: TextStyle(
          //         fontSize: 13,
          //         fontWeight: FontWeight.w700,
          //         color: badgeTextColor ?? const Color(0xFF334155),
          //       ),
          //     ),
          //   ),
          // ],
          if (hasAction) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: iconColor,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(actionIcon ?? Icons.arrow_forward_rounded),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodMacroSummaryCard extends StatelessWidget {
  const _FoodMacroSummaryCard({
    required this.analysis,
  });

  final FoodMacroAnalysis analysis;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodMacroSummaryRow(
            label: 'Makanan',
            value: analysis.detectedFoods.isEmpty
                ? '-'
                : analysis.detectedFoods.join(', '),
          ),
          _FoodMacroSummaryRow(
            label: 'Porsi',
            value: analysis.portionEstimate.isEmpty
                ? '-'
                : analysis.portionEstimate,
          ),
          _FoodMacroSummaryRow(
            label: 'Estimasi Gram',
            value: '${_formatNumber(analysis.portionGramsEstimate)} g',
          ),
          if (analysis.fdcFoodId.isNotEmpty)
            _FoodMacroSummaryRow(
              label: 'FDC Food ID',
              value: analysis.fdcFoodId,
            ),
          _FoodMacroSummaryRow(
            label: 'Kalori',
            value: '${_formatNumber(analysis.caloriesKcal)} kkal',
          ),
          _FoodMacroSummaryRow(
            label: 'Protein',
            value: '${_formatNumber(analysis.proteinG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Karbohidrat',
            value: '${_formatNumber(analysis.carbsG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Gula',
            value: '${_formatNumber(analysis.sugarG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Serat',
            value: '${_formatNumber(analysis.fiberG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Lemak',
            value: '${_formatNumber(analysis.fatG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Lemak Jenuh',
            value: '${_formatNumber(analysis.saturatedFatG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Lemak Tak Jenuh Tunggal',
            value: '${_formatNumber(analysis.monounsaturatedFatG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Lemak Tak Jenuh Ganda',
            value: '${_formatNumber(analysis.polyunsaturatedFatG)} g',
          ),
          _FoodMacroSummaryRow(
            label: 'Kolesterol',
            value: '${_formatNumber(analysis.cholesterolMg)} mg',
          ),
          _FoodMacroSummaryRow(
            label: 'Kalsium',
            value: '${_formatNumber(analysis.calciumMg)} mg',
          ),
          _FoodMacroSummaryRow(
            label: 'Confidence',
            value: analysis.confidence.isEmpty ? '-' : analysis.confidence,
          ),
          if (analysis.notes.isNotEmpty)
            _FoodMacroSummaryRow(
              label: 'Catatan',
              value: analysis.notes,
            ),
        ],
      ),
    );
  }
}

class _FoodMacroSummaryRow extends StatelessWidget {
  const _FoodMacroSummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C2D12),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
