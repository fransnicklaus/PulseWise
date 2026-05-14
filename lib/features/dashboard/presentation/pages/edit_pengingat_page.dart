import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/medication_history_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

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
    'capsule',
    'drops',
    'syrup',
    'liquid',
  ];

  static const List<String> _doseUnits = [
    'mg',
    'ml',
    'tablet',
    'kapsul',
    'tetes',
  ];

  static const Map<String, Color> _colorOptions = {
    'red': Color(0xFFEF4444),
    'orange': Color(0xFFF97316),
    'yellow': Color(0xFFEAB308),
    'green': Color(0xFF22C55E),
    'blue': Color(0xFF3B82F6),
    'purple': Color(0xFF8B5CF6),
    'white': Color(0xFFE2E8F0),
  };

  final _doseController = TextEditingController();
  final _noteController = TextEditingController();

  late Future<MedicationItem> _detailFuture;

  bool _isInitialized = false;
  bool _isSaving = false;

  String _selectedForm = 'pill';
  String _selectedColor = 'red';
  String _selectedDoseUnit = 'mg';
  String _selectedFrequency = 'daily';
  String _initialFrequency = 'daily';
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
    _detailFuture =
        ref.read(profileApiProvider).fetchMedicationDetail(widget.medicationId);
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
          title: 'Edit Pengingat',
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
            return _ErrorState(
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _retry,
            );
          }

          final item = snapshot.data;
          if (item == null) {
            return _ErrorState(
              message: 'Detail medication tidak ditemukan',
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
                    title: 'Bentuk Obat',
                    child: DropdownButtonFormField<String>(
                      value: _selectedForm,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration('Pilih bentuk obat'),
                      items: _forms
                          .map(
                            (form) => DropdownMenuItem(
                              value: form,
                              child: Text(form),
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
                    title: 'Warna Obat',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.entries.map((entry) {
                        final selected = _selectedColor == entry.key;
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () =>
                              setState(() => _selectedColor = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFE7EE)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFE64060)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Dosis',
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
                            decoration: _inputDecoration('Jumlah dosis'),
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
                    title: 'Frekuensi Minum',
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
                    title: 'Jam Minum',
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
                              'Tambah Jam Minum',
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
    _selectedForm = item.form.toLowerCase().trim().isEmpty
        ? 'pill'
        : item.form.toLowerCase().trim();
    _selectedColor = _colorOptions.containsKey(item.color.toLowerCase().trim())
        ? item.color.toLowerCase().trim()
        : 'red';
    _selectedFrequency =
        item.frequency.toLowerCase() == 'weekly' ? 'weekly' : 'daily';
    _initialFrequency = _selectedFrequency;
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
          .read(profileApiProvider)
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
      AppToast.warning(context, 'Dosis harus angka dan lebih dari 0.');
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
      AppToast.warning(context, 'Tambahkan minimal satu jam minum.');
      return;
    }

    final intakeTimes = _intakeTimes.map(_formatTime).toList();
    if (intakeTimes.toSet().length != intakeTimes.length) {
      AppToast.warning(context, 'Jam minum tidak boleh sama.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(profileApiProvider).updateMedication(
            medicationId: widget.medicationId,
            form: _selectedForm,
            color: _selectedColor,
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
