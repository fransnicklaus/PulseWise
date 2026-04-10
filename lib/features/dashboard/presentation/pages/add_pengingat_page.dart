import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

class AddPengingatPage extends StatefulWidget {
  const AddPengingatPage({super.key});

  @override
  State<AddPengingatPage> createState() => _AddPengingatPageState();
}

class _AddPengingatPageState extends State<AddPengingatPage> {
  static const Map<String, String> _formIcons = {
    'Pill':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-pill-icon lucide-pill"><path d="m10.5 20.5 10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7Z"/><path d="m8.5 8.5 7 7"/></svg>''',
    'Tablet':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-tablets-icon lucide-tablets"><circle cx="7" cy="7" r="5"/><circle cx="17" cy="17" r="5"/><path d="M12 17h10"/><path d="m3.46 10.54 7.08-7.08"/></svg>''',
    'Kapsul':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-pill-bottle-icon lucide-pill-bottle"><path d="M18 11h-4a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1h4"/><path d="M6 7v13a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7"/><rect width="16" height="5" x="4" y="2" rx="1"/></svg>''',
    'Tetes':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-droplet-icon lucide-droplet"><path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/></svg>''',
    'Sirup':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-milk-icon lucide-milk"><path d="M8 2h8"/><path d="M9 2v2.789a4 4 0 0 1-.672 2.219l-.656.984A4 4 0 0 0 7 10.212V20a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-9.789a4 4 0 0 0-.672-2.219l-.656-.984A4 4 0 0 1 15 4.788V2"/><path d="M7 15a6.472 6.472 0 0 1 5 0 6.47 6.47 0 0 0 5 0"/></svg>''',
    'Cairan':
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-glass-water-icon lucide-glass-water"><path d="M5.116 4.104A1 1 0 0 1 6.11 3h11.78a1 1 0 0 1 .994 1.105L17.19 20.21A2 2 0 0 1 15.2 22H8.8a2 2 0 0 1-2-1.79z"/><path d="M6 12a5 5 0 0 1 6 0 5 5 0 0 0 6 0"/></svg>''',
  };

  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _formSearchController = TextEditingController();
  final _doseController = TextEditingController();
  final _frequencyCountController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  final List<String> _forms = [
    'Pill',
    'Tablet',
    'Kapsul',
    'Cairan',
    'Sirup',
    'Tetes'
  ];
  final List<String> _doseUnits = ['mg', 'ml', 'tablet', 'kapsul', 'tetes'];

  String? _selectedForm;
  String _formSearchQuery = '';
  String _selectedDoseUnit = 'mg';
  String _selectedFrequencyType = 'Per Hari';

  final Set<String> _periods = {};
  final List<TimeOfDay> _customTimes = [];
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _formSearchController.dispose();
    _doseController.dispose();
    _frequencyCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F5F7B)),
        ),
        title: const Text(
          'Tambah Pengingat',
          style: TextStyle(
            color: Color(0xFF4F5F7B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
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
    );
  }

  Widget _buildStepIndicator() {
    final labels = [
      'Nama & Bentuk',
      'Dosis',
      'Jadwal',
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
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
            'Langkah ${_currentStep + 1} dari 3: ${labels[_currentStep]}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) return _buildStepOne();
    if (_currentStep == 1) return _buildStepTwo();
    return _buildStepThree();
  }

  Widget _buildStepOne() {
    final filteredForms = _forms
        .where(
          (item) => item.toLowerCase().contains(_formSearchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Nama Obat',
          child: TextField(
            controller: _nameController,
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
                              child: _buildFormIcon(item),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
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
                              setState(() => _selectedForm = value);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormIcon(String form) {
    final svg = _formIcons[form];
    if (svg == null) {
      return const SizedBox(width: 24, height: 24);
    }

    return SvgPicture.string(
      svg,
      width: 22,
      height: 22,
      colorFilter: const ColorFilter.mode(Color(0xFFE64060), BlendMode.srcIn),
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
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
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
          title: 'Periode Waktu',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _periodChip('Pagi'),
              _periodChip('Siang'),
              _periodChip('Malam'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Waktu Khusus',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customTimes
                    .map((time) => Chip(
                          label: Text(_formatTime(time)),
                          onDeleted: () {
                            setState(() => _customTimes.remove(time));
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addCustomTime,
                icon: const Icon(Icons.access_time),
                label: const Text('Tambah Waktu'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Frekuensi',
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFrequencyType,
                  dropdownColor: Colors.white,
                  iconEnabledColor: const Color(0xFF64748B),
                  decoration: _inputDecoration('Tipe').copyWith(
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Per Hari', child: Text('Per Hari')),
                    DropdownMenuItem(
                        value: 'Per Minggu', child: Text('Per Minggu')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFrequencyType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _frequencyCountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Jumlah'),
                ),
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
                    style: const TextStyle(fontSize: 15),
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

  Widget _buildBottomActions() {
    final isLast = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep -= 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kembali'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: isLast ? _saveReminder : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(isLast ? 'Simpan Pengingat' : 'Lanjut'),
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
              fontSize: 14,
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

  Widget _periodChip(String label) {
    final selected = _periods.contains(label);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (selected) {
            _periods.remove(label);
          } else {
            _periods.add(label);
          }
        });
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFE64060) : const Color(0xFF475569),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
      ),
      showCheckmark: true,
      checkmarkColor: const Color(0xFFE64060),
    );
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _customTimes.add(picked));
    }
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _selectedForm == null) {
        _showError('Isi nama dan pilih bentuk terlebih dahulu.');
        return;
      }
    }
    if (_currentStep == 1) {
      if (_doseController.text.trim().isEmpty) {
        _showError('Isi besar dosis terlebih dahulu.');
        return;
      }
    }

    setState(() => _currentStep += 1);
  }

  void _saveReminder() {
    if (_periods.isEmpty && _customTimes.isEmpty) {
      _showError('Pilih minimal satu periode atau satu waktu khusus.');
      return;
    }

    if (_frequencyCountController.text.trim().isEmpty) {
      _showError('Isi jumlah frekuensi.');
      return;
    }

    AppToast.success(context, 'Pengingat berhasil disimpan');
    context.pop();
  }

  void _showError(String message) {
    AppToast.warning(context, message);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
