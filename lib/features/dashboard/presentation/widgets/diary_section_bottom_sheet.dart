import 'dart:async';

import 'package:flutter/material.dart';

class DiarySectionBottomSheet extends StatefulWidget {
  final String title;
  final ScrollController? scrollController;

  const DiarySectionBottomSheet({
    super.key,
    required this.title,
    this.scrollController,
  });

  @override
  State<DiarySectionBottomSheet> createState() =>
      _DiarySectionBottomSheetState();
}

class _DiarySectionBottomSheetState extends State<DiarySectionBottomSheet> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _symptomSearchController =
      TextEditingController();
  final TextEditingController _activitySearchController =
      TextEditingController();
  final TextEditingController _symptomOtherController = TextEditingController();
  final TextEditingController _symptomDescriptionController =
      TextEditingController();
  final TextEditingController _mealNameController = TextEditingController();
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedMood = 'Biasa Saja';
  final Set<String> _selectedSymptoms = {};
  String _symptomSearchQuery = '';
  String _activitySearchQuery = '';
  String? _selectedActivity;
  TimeOfDay _activityStartTime = TimeOfDay.now();
  TimeOfDay _activityEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  String get _normalizedSectionTitle => widget.title.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _configureSectionLifecycle();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _conditionController.dispose();
    _symptomSearchController.dispose();
    _activitySearchController.dispose();
    _symptomOtherController.dispose();
    _symptomDescriptionController.dispose();
    _mealNameController.dispose();
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

  void _saveMetriksKesehatan() {
    Navigator.of(context).pop({
      'section': widget.title,
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
      'weightKg': _weightController.text.trim(),
      'systolic': _systolicController.text.trim(),
      'diastolic': _diastolicController.text.trim(),
      'heartRate': _heartRateController.text.trim(),
    });
  }

  void _saveGejala() {
    if (_selectedSymptoms.isEmpty) {
      _showValidationError('Pilih minimal satu gejala.');
      return;
    }

    if (_selectedSymptoms.contains('Lain-lainnya') &&
        _symptomOtherController.text.trim().isEmpty) {
      _showValidationError('Tulis gejala lainnya sebelum menyimpan.');
      return;
    }

    if (_symptomDescriptionController.text.trim().isEmpty) {
      _showValidationError('Mohon isi deskripsi gejala.');
      return;
    }

    final selectedRaw = _selectedSymptoms.toList();
    final selectedResolved = selectedRaw.map((symptom) {
      if (symptom != 'Lain-lainnya') return symptom;
      final otherText = _symptomOtherController.text.trim();
      return otherText.isEmpty ? 'Lain-lainnya' : otherText;
    }).toList();

    Navigator.of(context).pop({
      'section': widget.title,
      'symptoms': selectedResolved,
      'symptomsRaw': selectedRaw,
      'description': _symptomDescriptionController.text.trim(),
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
    });
  }

  void _saveAktivitas() {
    if (_selectedActivity == null || _selectedActivity!.trim().isEmpty) {
      _showValidationError('Pilih satu jenis aktivitas.');
      return;
    }

    if (_toMinutes(_activityEndTime) <= _toMinutes(_activityStartTime)) {
      _showValidationError('Waktu selesai harus setelah waktu mulai.');
      return;
    }

    Navigator.of(context).pop({
      'section': widget.title,
      'activity': _selectedActivity,
      'startTime': _formatTime(_activityStartTime),
      'endTime': _formatTime(_activityEndTime),
    });
  }

  void _saveKonsumsi() {
    final foodName = _mealNameController.text.trim();
    final foodDescription = _mealDescriptionController.text.trim();

    if (foodName.isEmpty) {
      _showValidationError('Mohon isi nama makanan.');
      return;
    }

    if (foodDescription.isEmpty) {
      _showValidationError('Mohon isi deskripsi atau daftar bahan.');
      return;
    }

    Navigator.of(context).pop({
      'section': widget.title,
      'time': _formatTime(_selectedTime),
      'useCurrentTime': _useCurrentTime,
      'foodName': foodName,
      'description': foodDescription,
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

  void _configureSectionLifecycle() {
    switch (_normalizedSectionTitle) {
      case 'metriks kesehatan':
      case 'kondisi':
      case 'gejala':
      case 'konsumsi harian':
        _startLiveClock();
        break;
      default:
        break;
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
      case 'konsumsi harian':
        return _buildKonsumsiContent();
      default:
        return const SizedBox(height: 8);
    }
  }

  Widget _buildMetriksKesehatanContent() {
    return Column(
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
          style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Contoh: 72',
            suffixText: 'Kg',
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
                style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Sistolik',
                  suffixText: 'mmHg',
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
                style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Diastolik',
                  suffixText: 'mmHg',
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
          style: const TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Contoh: 72',
            suffixText: 'BPM',
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
            onPressed: _saveMetriksKesehatan,
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

    return Column(
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        });
                      },
                    );
                  },
                ),
        ),
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveGejala,
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

  Widget _buildAktivitasContent() {
    final filteredActivities = _activityOptions
        .where(
          (item) => item
              .toLowerCase()
              .contains(_activitySearchQuery.trim().toLowerCase()),
        )
        .toList();

    return Column(
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
                        setState(() => _selectedActivity = value);
                      },
                    );
                  },
                ),
        ),
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveAktivitas,
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

  Widget _buildKonsumsiContent() {
    return Column(
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
          'Nama Makanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mealNameController,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Bubur ayam',
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
        const SizedBox(height: 18),
        const Text(
          'Deskripsi / Daftar Bahan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mealDescriptionController,
          minLines: 4,
          maxLines: 6,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: nasi, ayam suwir, daun bawang, kuah kaldu...',
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveKonsumsi,
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
