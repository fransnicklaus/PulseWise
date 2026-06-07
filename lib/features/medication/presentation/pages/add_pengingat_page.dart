import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';

class AddPengingatPage extends ConsumerStatefulWidget {
  const AddPengingatPage({super.key});

  @override
  ConsumerState<AddPengingatPage> createState() => _AddPengingatPageState();
}

class _AddPengingatPageState extends ConsumerState<AddPengingatPage> {
  static const Map<String, String> _formIcons = {
    'Pill':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m10.5 20.5 10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7Z"/><path d="m8.5 8.5 7 7"/></svg>''',
    'Tablet':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="7" r="5"/><circle cx="17" cy="17" r="5"/><path d="M12 17h10"/><path d="m3.46 10.54 7.08-7.08"/></svg>''',
    'Kapsul':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 11h-4a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1h4"/><path d="M6 7v13a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7"/><rect width="16" height="5" x="4" y="2" rx="1"/></svg>''',
    'Tetes':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/></svg>''',
    'Sirup':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2h8"/><path d="M9 2v2.789a4 4 0 0 1-.672 2.219l-.656.984A4 4 0 0 0 7 10.212V20a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-9.789a4 4 0 0 0-.672-2.219l-.656-.984A4 4 0 0 1 15 4.788V2"/><path d="M7 15a6.472 6.472 0 0 1 5 0 6.47 6.47 0 0 0 5 0"/></svg>''',
    'Cairan':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5.116 4.104A1 1 0 0 1 6.11 3h11.78a1 1 0 0 1 .994 1.105L17.19 20.21A2 2 0 0 1 15.2 22H8.8a2 2 0 0 1-2-1.79z"/><path d="M6 12a5 5 0 0 1 6 0 5 5 0 0 0 6 0"/></svg>''',
  };

  static const List<String> _forms = [
    'Pill',
    'Tablet',
    'Kapsul',
    'Cairan',
    'Sirup',
    'Tetes',
  ];

  static const List<String> _doseUnits = [
    'mg',
    'ml',
    'tablet',
    'kapsul',
    'tetes'
  ];

  static const List<String> _weekdays = [
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab'
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

  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _formSearchController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedForm;
  String _formSearchQuery = '';
  String _selectedDoseUnit = 'mg';
  Color _selectedMedicationColor = _medicationColors.first;

  String _selectedFrequencyMode = 'Daily';
  int _dailyEvery = 1;
  final Set<int> _selectedWeekdays = {};
  DateTime _startDate = DateTime.now();

  int _intakeCount = 1;
  List<TimeOfDay> _intakeTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _formSearchController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Tambah Pengingat',
        // subtitle: 'Tambahkan kontak darurat baru',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     onPressed: _isSubmitting ? null : () => context.pop(),
      //     icon: const Icon(Icons.arrow_back, color: Color(0xFF4F5F7B)),
      //   ),
      //   title: const Text(
      //     'Tambah Pengingat',
      //     style: TextStyle(
      //       color: Color(0xFF4F5F7B),
      //       fontSize: 20,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = [
      'Nama, Bentuk, Warna',
      'Dosis',
      'Frekuensi',
      'Jumlah Minum',
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE64060)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Langkah ${_currentStep + 1} dari 4: ${labels[_currentStep]}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildStepThree();
      default:
        return _buildStepFour();
    }
  }

  Widget _buildStepOne() {
    final filteredForms = _forms
        .where((item) =>
            item.toLowerCase().contains(_formSearchQuery.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Nama Obat',
          child: TextField(
            controller: _nameController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration('Contoh: Obat Jantung'),
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Bentuk',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _formSearchController,
                enabled: !_isSubmitting,
                onChanged: (value) {
                  setState(() => _formSearchQuery = value);
                },
                decoration: _inputDecoration('Cari bentuk...').copyWith(
                  prefixIcon: const Icon(Icons.search),
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
                child: filteredForms.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Bentuk tidak ditemukan',
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
                        itemCount: filteredForms.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFE2E8F0),
                        ),
                        itemBuilder: (_, index) {
                          final item = filteredForms[index];
                          return RadioListTile<String>(
                            value: item,
                            groupValue: _selectedForm,
                            activeColor: const Color(0xFFE64060),
                            secondary: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFormIcon(
                                  item, _selectedMedicationColor),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              item,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedForm == item
                                    ? const Color(0xFFE64060)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            onChanged: (value) {
                              if (_isSubmitting) return;
                              setState(() => _selectedForm = value);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Warna Obat',
          child: SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _medicationColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final color = _medicationColors[index];
                final selected = color == _selectedMedicationColor;
                return GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _selectedMedicationColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected ? const Color(0xFF0F172A) : Colors.white,
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
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Besar Dosis',
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _doseController,
                  enabled: !_isSubmitting,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Contoh: 2'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDoseUnit,
                  dropdownColor: Colors.white,
                  iconEnabledColor: const Color(0xFF64748B),
                  decoration: _inputDecoration('Satuan').copyWith(
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: _doseUnits
                      .map((unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit)))
                      .toList(),
                  onChanged: (value) {
                    if (_isSubmitting) return;
                    if (value != null) {
                      setState(() => _selectedDoseUnit = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Catatan (Opsional)',
          child: TextField(
            controller: _notesController,
            enabled: !_isSubmitting,
            maxLines: 3,
            decoration: _inputDecoration('Contoh: diminum setelah makan'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Seberapa sering obat diminum',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _frequencyModeButton('Daily', 'Harian'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _frequencyModeButton('Weekly', 'Mingguan'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_selectedFrequencyMode == 'Daily')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setiap berapa hari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              child: _stepperButton(
                                icon: Icons.remove,
                                onTap: _dailyEvery > 1
                                    ? () => setState(() => _dailyEvery -= 1)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  '$_dailyEvery Hari',
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 44,
                              child: _stepperButton(
                                icon: Icons.add,
                                onTap: _dailyEvery < 10
                                    ? () => setState(() => _dailyEvery += 1)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih hari',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _weekdays.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final selected = _selectedWeekdays.contains(index);
                          return ChoiceChip(
                            label: Text(
                              _weekdays[index],
                              style: TextStyle(fontSize: 15),
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedWeekdays.remove(index);
                                } else {
                                  _selectedWeekdays.add(index);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFFFE7EE),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected
                                  ? const Color(0xFFE64060)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFFE64060)
                                  : const Color(0xFFE2E8F0),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Tanggal Mulai',
          child: InkWell(
            onTap: _pickStartDate,
            child: InputDecorator(
              decoration: _inputDecoration('Tanggal mulai'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepFour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Sehari berapa banyak minumnya',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: _stepperButton(
                          icon: Icons.remove,
                          onTap: _intakeCount > 1
                              ? () => _setIntakeCount(_intakeCount - 1)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            '$_intakeCount Kali',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: _stepperButton(
                          icon: Icons.add,
                          onTap: _intakeCount < 8
                              ? () => _setIntakeCount(_intakeCount + 1)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_intakeCount, (index) {
                final label = '${_ordinalIntake(index + 1)} intake';
                final selectedTime = _intakeTimes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: OutlinedButton(
                          onPressed: () => _pickIntakeTime(index),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(selectedTime),
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _frequencyModeButton(String value, String label) {
    final selected = _selectedFrequencyMode == value;
    return OutlinedButton(
      onPressed: _isSubmitting
          ? null
          : () => setState(() => _selectedFrequencyMode = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFFFE7EE) : Colors.white,
        foregroundColor:
            selected ? const Color(0xFFE64060) : const Color(0xFF475569),
        side: BorderSide(
          color: selected ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Widget _stepperButton(
      {required IconData icon, required VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
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

  Widget _buildBottomActions() {
    final isLast = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _currentStep -= 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kembali',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isSubmitting ? null : (isLast ? _saveReminder : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: isLast && _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast ? 'Simpan Pengingat' : 'Lanjut',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF475569).withOpacity(0.45),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildFormIcon(String form, Color color) {
    final svg = _formIcons[form];
    if (svg == null) {
      return const SizedBox(width: 24, height: 24);
    }

    return SvgPicture.string(
      svg,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
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

  void _setIntakeCount(int value) {
    setState(() {
      _intakeCount = value;
      if (_intakeTimes.length < value) {
        _intakeTimes = [
          ..._intakeTimes,
          ...List.generate(
            value - _intakeTimes.length,
            (i) => _defaultIntakeTime(_intakeTimes.length + i),
          ),
        ];
      } else if (_intakeTimes.length > value) {
        _intakeTimes = _intakeTimes.sublist(0, value);
      }
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _selectedForm == null) {
        _showError('Isi nama dan pilih bentuk terlebih dahulu.');
        return;
      }
    }

    if (_currentStep == 1) {
      final doseValue = _doseController.text.trim();
      if (doseValue.isEmpty) {
        _showError('Isi besar dosis terlebih dahulu.');
        return;
      }
      if (num.tryParse(doseValue) == null) {
        _showError('Besar dosis hanya boleh angka.');
        return;
      }
    }

    if (_currentStep == 2) {
      if (_selectedFrequencyMode == 'Weekly' && _selectedWeekdays.isEmpty) {
        _showError('Pilih minimal satu hari untuk jadwal mingguan.');
        return;
      }
    }

    setState(() => _currentStep += 1);
  }

  Future<void> _saveReminder() async {
    if (_isSubmitting) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Nama obat wajib diisi.');
      return;
    }

    final selectedForm = _selectedForm?.trim();
    if (selectedForm == null || selectedForm.isEmpty) {
      _showError('Bentuk obat wajib dipilih.');
      return;
    }

    final doseValue = _doseController.text.trim();
    final parsedDose = num.tryParse(doseValue);
    if (parsedDose == null || parsedDose <= 0) {
      _showError('Besar dosis harus berupa angka lebih dari 0.');
      return;
    }

    if (_selectedFrequencyMode == 'Weekly' && _selectedWeekdays.isEmpty) {
      _showError('Pilih minimal satu hari untuk jadwal mingguan.');
      return;
    }

    if (_intakeTimes.isEmpty || _intakeTimes.length != _intakeCount) {
      _showError('Waktu minum belum lengkap.');
      return;
    }

    final formattedIntakeTimes = _intakeTimes.map(_formatTime).toList();
    final uniqueIntakeTimes = formattedIntakeTimes.toSet();
    if (uniqueIntakeTimes.length != formattedIntakeTimes.length) {
      _showError('Waktu minum tidak boleh sama.');
      return;
    }

    final isWeekly = _selectedFrequencyMode == 'Weekly';
    final apiDaysOfWeek = _selectedWeekdays.map(_toApiDayOfWeek).toList()
      ..sort();

    setState(() => _isSubmitting = true);
    try {
      await ref.read(medicationApiProvider).addMedication(
            name: name,
            form: selectedForm.toLowerCase(),
            color: _hexColor(_selectedMedicationColor),
            singleDose: parsedDose,
            singleDoseUnit: _selectedDoseUnit,
            startDate: _formatDateOnly(_startDate),
            frequency: _selectedFrequencyMode.toLowerCase(),
            numOfDays: isWeekly ? null : _dailyEvery,
            daysOfWeek: isWeekly ? apiDaysOfWeek : null,
            intakeTimes: formattedIntakeTimes,
            note: _notesController.text.trim(),
          );

      if (!mounted) return;
      invalidateMedicationCalendarCache(ref);
      ref.read(dashboardNavIndexProvider.notifier).state = 3;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    AppToast.warning(context, message);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _hexColor(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  String _ordinalIntake(int number) {
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }

  TimeOfDay _defaultIntakeTime(int index) {
    final hour = (8 + index) % 24;
    return TimeOfDay(hour: hour, minute: 0);
  }

  int _toApiDayOfWeek(int selectedIndex) {
    // Backend convention: Monday=1 ... Saturday=6, Sunday=7.
    if (selectedIndex == 0) return 7;
    return selectedIndex;
  }
}
