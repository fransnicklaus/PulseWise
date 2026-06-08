import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_history_provider.dart';

class EditPengingatPage extends ConsumerStatefulWidget {
  const EditPengingatPage({
    super.key,
    required this.medicationId,
  });

  final String medicationId;

  @override
  ConsumerState<EditPengingatPage> createState() => _EditPengingatPageState();
}

class _EditPengingatPageState extends ConsumerState<EditPengingatPage> {
  static const List<String> _forms = [
    'pill',
    'tablet',
    'kapsul',
    'tetes',
    'sirup',
    'cairan',
  ];

  static const Map<String, String> _formLabels = {
    'pill': 'Pill',
    'tablet': 'Tablet',
    'kapsul': 'Kapsul',
    'tetes': 'Tetes',
    'sirup': 'Sirup',
    'cairan': 'Cairan',
  };

  static const List<String> _doseUnits = [
    'mg',
    'ml',
    'tablet',
    'kapsul',
    'tetes',
  ];

  static const List<Color> _medicationColors = [
    Color(0xFFE64060),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  final _doseController = TextEditingController();
  final _noteController = TextEditingController();

  late Future<MedicationItem> _detailFuture;

  bool _isInitialized = false;
  bool _isSaving = false;

  String _selectedForm = 'pill';
  String _selectedDoseUnit = 'mg';
  Color _selectedMedicationColor = _medicationColors.first;
  String _selectedFrequency = 'daily';
  int _dailyEvery = 1;
  DateTime _startDate = DateTime.now();
  List<int> _selectedDaysOfWeek = [];
  List<TimeOfDay> _intakeTimes = [const TimeOfDay(hour: 8, minute: 0)];

  static const List<_DayOption> _dayOptions = [
    _DayOption(label: 'Sen', value: 1),
    _DayOption(label: 'Sel', value: 2),
    _DayOption(label: 'Rab', value: 3),
    _DayOption(label: 'Kam', value: 4),
    _DayOption(label: 'Jum', value: 5),
    _DayOption(label: 'Sab', value: 6),
    _DayOption(label: 'Min', value: 7),
  ];

  @override
  void initState() {
    super.initState();
    _detailFuture = ref
        .read(medicationApiProvider)
        .fetchMedicationDetail(widget.medicationId);
  }

  @override
  void dispose() {
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
          title: 'Edit Rutinitas',
          showBackButton: true,
          onBackPressed: () {
            context.pop();
          }),
      body: FutureBuilder<MedicationItem>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE64060)),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error != null && isNetworkRequestError(error)) {
              return NoConnectionState.page(
                title: 'Form rutinitas belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil detail rutinitas untuk diedit karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: _retry,
              );
            }

            return _ErrorState(
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: _retry,
            );
          }

          final item = snapshot.data;
          if (item == null) {
            return _ErrorState(
              message: 'Detail rutinitas tidak ditemukan',
              onRetry: _retry,
            );
          }

          if (!_isInitialized) {
            _initializeForm(item);
          }

          return AbsorbPointer(
            absorbing: _isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    title: 'Bentuk Item',
                    child: DropdownButtonFormField<String>(
                      value: _selectedForm,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration('Pilih bentuk item'),
                      dropdownColor: Colors.white,
                      items: _forms
                          .map(
                            (form) => DropdownMenuItem(
                              value: form,
                              child: Text(_formLabels[form] ?? form),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedForm = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Warna Item',
                    child: SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _medicationColors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final color = _medicationColors[index];
                          final selected =
                              color.value == _selectedMedicationColor.value;
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedMedicationColor = color,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  width: selected ? 2.5 : 1.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Takaran',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _doseController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration('Jumlah takaran'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDoseUnit,
                            decoration: _inputDecoration('Satuan'),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            items: _doseUnits
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedDoseUnit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Tanggal Mulai',
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: InputDecorator(
                        decoration: _inputDecoration('Pilih tanggal mulai'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDateReadable(_startDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                size: 20, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Frekuensi Rutinitas',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _frequencyButton('daily', 'Harian'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _frequencyButton('weekly', 'Mingguan'),
                            ),
                          ],
                        ),
                        if (_selectedFrequency == 'daily') ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Setiap berapa hari',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 46,
                                  child: _stepperButton(
                                    icon: Icons.remove,
                                    onTap: _dailyEvery > 1
                                        ? () => setState(() => _dailyEvery -= 1)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '$_dailyEvery Hari',
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 46,
                                  child: _stepperButton(
                                    icon: Icons.add,
                                    onTap: _dailyEvery < 30
                                        ? () => setState(() => _dailyEvery += 1)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_selectedFrequency == 'weekly') ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dayOptions.map((day) {
                              final selected =
                                  _selectedDaysOfWeek.contains(day.value);
                              return ChoiceChip(
                                label: Text(day.label),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDaysOfWeek.remove(day.value);
                                    } else {
                                      _selectedDaysOfWeek.add(day.value);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFFFFE7EE),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? const Color(0xFFE64060)
                                      : const Color(0xFF475569),
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFFE64060)
                                      : const Color(0xFFE2E8F0),
                                ),
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Waktu Pengingat',
                    child: Column(
                      children: [
                        ...List.generate(_intakeTimes.length, (index) {
                          final time = _intakeTimes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _pickIntakeTime(index),
                                    style: OutlinedButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      side: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      _formatTime(time),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _intakeTimes.length <= 1
                                      ? null
                                      : () {
                                          setState(() {
                                            _intakeTimes.removeAt(index);
                                          });
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                  color: const Color(0xFFFF435D),
                                ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _intakeTimes.add(const TimeOfDay(
                                  hour: 8,
                                  minute: 0,
                                ));
                              });
                            },
                            icon: const Icon(Icons.add, size: 22),
                            label: const Text(
                              'Tambah Waktu',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Catatan (Opsional)',
                    child: TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration('Tambahkan catatan...'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF8B8C5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _initializeForm(MedicationItem item) {
    _isInitialized = true;
    _selectedForm = _normalizeFormValue(item.form);
    _selectedMedicationColor = _resolveMedicationColor(item.color);
    _selectedFrequency =
        item.frequency.toLowerCase() == 'weekly' ? 'weekly' : 'daily';
    _dailyEvery = (item.numOfDays ?? 0) > 0 ? item.numOfDays! : 1;
    _startDate = item.startDate ?? DateTime.now();
    _selectedDaysOfWeek =
        item.daysOfWeek.map((day) => day == 0 ? 7 : day).toSet().toList();

    final parsedTimes =
        item.intakeTimes.map(_timeFromString).whereType<TimeOfDay>().toList();
    _intakeTimes = parsedTimes.isEmpty
        ? [const TimeOfDay(hour: 8, minute: 0)]
        : parsedTimes;

    _doseController.text = _doseText(item.singleDose);
    _selectedDoseUnit = _doseUnits.contains(item.singleDoseUnit)
        ? item.singleDoseUnit
        : _doseUnits.first;
    _noteController.text = item.note ?? '';
  }

  void _retry() {
    setState(() {
      _isInitialized = false;
      _detailFuture = ref
          .read(medicationApiProvider)
          .fetchMedicationDetail(widget.medicationId);
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickIntakeTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _intakeTimes[index],
    );

    if (picked != null) {
      setState(() => _intakeTimes[index] = picked);
    }
  }

  Future<void> _submit() async {
    final dose = num.tryParse(_doseController.text.trim());
    if (dose == null || dose <= 0) {
      AppToast.warning(context, 'Takaran harus angka dan lebih dari 0.');
      return;
    }

    final unit = _selectedDoseUnit.trim();
    if (unit.isEmpty) {
      AppToast.warning(context, 'Satuan dosis wajib diisi.');
      return;
    }

    if (_selectedFrequency == 'weekly' && _selectedDaysOfWeek.isEmpty) {
      AppToast.warning(context, 'Pilih minimal satu hari untuk mingguan.');
      return;
    }

    if (_intakeTimes.isEmpty) {
      AppToast.warning(context, 'Tambahkan minimal satu waktu pengingat.');
      return;
    }

    final intakeTimes = _intakeTimes.map(_formatTime).toList();
    if (intakeTimes.toSet().length != intakeTimes.length) {
      AppToast.warning(context, 'Waktu pengingat tidak boleh sama.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(medicationApiProvider).updateMedication(
            medicationId: widget.medicationId,
            form: _selectedForm,
            color: _hexColor(_selectedMedicationColor),
            singleDose: dose,
            singleDoseUnit: unit,
            startDate: _formatDateOnly(_startDate),
            frequency: _selectedFrequency,
            numOfDays: _selectedFrequency == 'daily' ? _dailyEvery : null,
            daysOfWeek: _selectedDaysOfWeek..sort(),
            intakeTimes: intakeTimes,
            note: _noteController.text,
          );

      if (!mounted) return;

      invalidateMedicationCalendarCache(ref);
      ref.invalidate(medicationDetailProvider(widget.medicationId));
      await ref.read(medicationHistoryProvider.notifier).refreshMedications();

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.warning(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _frequencyButton(String value, String label) {
    final selected = _selectedFrequency == value;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedFrequency = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFFFE7EE) : Colors.white,
        foregroundColor:
            selected ? const Color(0xFFE64060) : const Color(0xFF475569),
        side: BorderSide(
          color: selected ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? const Color(0xFFE64060) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF475569).withOpacity(0.45),
        fontSize: 16,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE64060)),
      ),
    );
  }

  String _formatDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateReadable(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _timeFromString(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _doseText(num dose) {
    return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  }

  String _hexColor(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  Color _resolveMedicationColor(String rawColor) {
    const namedFallbacks = {
      'red': Color(0xFFEF4444),
      'orange': Color(0xFFF97316),
      'yellow': Color(0xFFEAB308),
      'green': Color(0xFF22C55E),
      'blue': Color(0xFF3B82F6),
      'purple': Color(0xFF8B5CF6),
      'white': Color(0xFFE2E8F0),
      'pink': Color(0xFFEC4899),
    };

    final normalized = rawColor.toLowerCase().trim();
    if (namedFallbacks.containsKey(normalized)) {
      return namedFallbacks[normalized]!;
    }

    final cleaned = normalized.replaceFirst('#', '');
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) {
      return _medicationColors.first;
    }

    final color =
        cleaned.length <= 6 ? Color(0xFF000000 | parsed) : Color(parsed);

    for (final paletteColor in _medicationColors) {
      if (paletteColor.value == color.value) {
        return paletteColor;
      }
    }

    return _medicationColors.first;
  }

  String _normalizeFormValue(String rawForm) {
    final normalized = rawForm.toLowerCase().trim();
    switch (normalized) {
      case 'pill':
      case 'tablet':
      case 'kapsul':
      case 'tetes':
      case 'sirup':
      case 'cairan':
        return normalized;
      case 'capsule':
        return 'kapsul';
      case 'drops':
        return 'tetes';
      case 'syrup':
        return 'sirup';
      case 'liquid':
        return 'cairan';
      default:
        return 'pill';
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayOption {
  const _DayOption({required this.label, required this.value});

  final String label;
  final int value;
}
