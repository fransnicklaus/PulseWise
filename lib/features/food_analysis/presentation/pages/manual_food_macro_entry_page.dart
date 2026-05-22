import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';

typedef SaveManualFoodConsumptionCallback = Future<void> Function(
  Map<String, dynamic> payload,
);

class ManualFoodMacroEntryPage extends StatefulWidget {
  const ManualFoodMacroEntryPage({
    super.key,
    this.onSaveConsumption,
    this.consumptionTypeLabel,
    this.consumptionTypeApi,
    this.consumptionTime,
    this.useCurrentTime = true,
  });

  final SaveManualFoodConsumptionCallback? onSaveConsumption;
  final String? consumptionTypeLabel;
  final String? consumptionTypeApi;
  final String? consumptionTime;
  final bool useCurrentTime;

  @override
  State<ManualFoodMacroEntryPage> createState() =>
      _ManualFoodMacroEntryPageState();
}

class _ManualFoodMacroEntryPageState extends State<ManualFoodMacroEntryPage> {
  static const List<_MealCategoryOption> _mealCategoryOptions = [
    _MealCategoryOption(value: 'Makanan Berat', label: 'Makanan Berat'),
    _MealCategoryOption(value: 'Makanan Ringan', label: 'Makanan Ringan'),
    _MealCategoryOption(value: 'Minuman', label: 'Minuman'),
  ];

  final _mealNameController = TextEditingController();
  final _portionController = TextEditingController();
  final _noteController = TextEditingController();
  final _portionGramsController = TextEditingController();
  final _fdcFoodIdController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _fatController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _monounsaturatedFatController = TextEditingController();
  final _polyunsaturatedFatController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _calciumController = TextEditingController();

  bool _isSaving = false;
  String? _formError;
  String? _nameError;
  String? _portionError;
  late String _selectedMealCategory;

  @override
  void initState() {
    super.initState();
    _selectedMealCategory = _normalizeMealCategory(
      widget.consumptionTypeApi,
      fallbackLabel: widget.consumptionTypeLabel,
    );
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _portionController.dispose();
    _noteController.dispose();
    _portionGramsController.dispose();
    _fdcFoodIdController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _fatController.dispose();
    _saturatedFatController.dispose();
    _monounsaturatedFatController.dispose();
    _polyunsaturatedFatController.dispose();
    _cholesterolController.dispose();
    _calciumController.dispose();
    super.dispose();
  }

  String get _resolvedTime {
    final raw = widget.consumptionTime?.trim() ?? '';
    return raw.isEmpty ? '--:--' : raw;
  }

  String _normalizeMealCategory(String? raw, {String? fallbackLabel}) {
    switch ((raw?.trim().toLowerCase() ?? '')) {
      case 'makanan berat':
      case 'breakfast':
      case 'sarapan':
      case 'lunch':
      case 'makan siang':
      case 'dinner':
      case 'makan malam':
      case 'food':
      case 'makanan':
        return 'Makanan Berat';
      case 'makanan ringan':
      case 'snack':
      case 'cemilan':
      case 'camilan':
      case 'other':
      case 'lainnya':
        return 'Makanan Ringan';
      case 'minuman':
      case 'drink':
        return 'Minuman';
      default:
        switch ((fallbackLabel?.trim().toLowerCase() ?? '')) {
          case 'makanan berat':
          case 'sarapan':
          case 'makan siang':
          case 'makan malam':
            return 'Makanan Berat';
          case 'makanan ringan':
          case 'snack':
          case 'cemilan':
          case 'camilan':
          case 'lainnya':
            return 'Makanan Ringan';
          case 'minuman':
            return 'Minuman';
          default:
            return _mealCategoryOptions.first.value;
        }
    }
  }

  String _formatMealCategoryLabel(String value) {
    for (final option in _mealCategoryOptions) {
      if (option.value == value) return option.label;
    }
    return _mealCategoryOptions.first.label;
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Map<String, dynamic> _buildNutritionPayload() {
    final payload = <String, dynamic>{
      'nutritionSource': 'manual_macro_input',
    };

    final energyKcal = _parseDouble(_caloriesController.text);
    final proteinG = _parseDouble(_proteinController.text);
    final carbohydrateG = _parseDouble(_carbsController.text);
    final sugarG = _parseDouble(_sugarController.text);
    final fiberG = _parseDouble(_fiberController.text);
    final totalFatG = _parseDouble(_fatController.text);
    final saturatedFatG = _parseDouble(_saturatedFatController.text);
    final monounsaturatedFatG =
        _parseDouble(_monounsaturatedFatController.text);
    final polyunsaturatedFatG =
        _parseDouble(_polyunsaturatedFatController.text);
    final cholesterolMg = _parseDouble(_cholesterolController.text);
    final calciumMg = _parseDouble(_calciumController.text);
    final portionGrams = _parseDouble(_portionGramsController.text);
    final fdcFoodId = _fdcFoodIdController.text.trim();

    if (energyKcal != null) payload['energyKcal'] = energyKcal;
    if (proteinG != null) payload['proteinG'] = proteinG;
    if (carbohydrateG != null) payload['carbohydrateG'] = carbohydrateG;
    if (sugarG != null) payload['sugarG'] = sugarG;
    if (fiberG != null) payload['fiberG'] = fiberG;
    if (totalFatG != null) payload['totalFatG'] = totalFatG;
    if (saturatedFatG != null) payload['saturatedFatG'] = saturatedFatG;
    if (monounsaturatedFatG != null) {
      payload['monounsaturatedFatG'] = monounsaturatedFatG;
    }
    if (polyunsaturatedFatG != null) {
      payload['polyunsaturatedFatG'] = polyunsaturatedFatG;
    }
    if (cholesterolMg != null) payload['cholesterolMg'] = cholesterolMg;
    if (calciumMg != null) payload['calciumMg'] = calciumMg;
    if (portionGrams != null && portionGrams > 0) {
      payload['portionGrams'] = portionGrams.round();
    }
    if (fdcFoodId.isNotEmpty) payload['fdcFoodId'] = fdcFoodId;

    return payload;
  }

  Future<void> _save() async {
    final mealName = _mealNameController.text.trim();
    final portion = FoodMacroAnalysis.truncatePortionText(
      _portionController.text.trim(),
    );
    final note = _noteController.text.trim();

    final missingName = mealName.isEmpty;
    final missingPortion = portion.isEmpty;
    if (missingName || missingPortion) {
      setState(() {
        _formError = null;
        _nameError = missingName ? 'Mohon isi nama konsumsi.' : null;
        _portionError = missingPortion ? 'Mohon isi porsi konsumsi.' : null;
      });
      return;
    }

    setState(() {
      _formError = null;
      _nameError = null;
      _portionError = null;
      _isSaving = true;
    });

    final payload = {
      'typeLabel': _formatMealCategoryLabel(_selectedMealCategory),
      'type': _selectedMealCategory,
      'name': mealName,
      'portion': portion,
      'time': _resolvedTime,
      'useCurrentTime': widget.useCurrentTime,
      'note': note,
      'nutritionPayload': _buildNutritionPayload(),
    };

    try {
      final onSaveConsumption = widget.onSaveConsumption;
      if (onSaveConsumption == null) {
        if (!mounted) return;
        Navigator.of(context).pop(payload);
        return;
      }

      await onSaveConsumption(payload);
      if (!mounted) return;
      Navigator.of(context).pop(const {'action': 'saved'});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Input Nutrisi Lengkap',
        subtitle: 'Isi konsumsi beserta data nutrisinya',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ManualMacroInfoCard(
                typeLabel: _formatMealCategoryLabel(_selectedMealCategory),
                timeLabel: _resolvedTime,
              ),
              const SizedBox(height: 16),
              _ManualMacroSection(
                title: 'Kategori Konsumsi',
                subtitle:
                    'Pilih kategori makan atau minum yang paling sesuai sebelum menyimpan.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _mealCategoryOptions
                      .map(
                        (option) => ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _selectedMealCategory == option.value
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          selected: _selectedMealCategory == option.value,
                          selectedColor: const Color(0xFFE64060),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          onSelected: (_) {
                            setState(() {
                              _selectedMealCategory = option.value;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _ManualMacroSection(
                title: 'Informasi Dasar',
                subtitle: 'Isi data utama konsumsi terlebih dahulu.',
                child: Column(
                  children: [
                    _ManualMacroTextField(
                      controller: _mealNameController,
                      label: 'Nama Konsumsi',
                      hintText: 'Contoh: nasi padang, teh hangat, biskuit',
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 14),
                    _ManualMacroTextField(
                      controller: _portionController,
                      label: 'Porsi',
                      hintText: 'Contoh: 1 piring, 1 gelas, 2 keping',
                      maxLength: FoodMacroAnalysis.maxPortionEstimateLength,
                      errorText: _portionError,
                    ),
                    const SizedBox(height: 14),
                    _ManualMacroTextField(
                      controller: _noteController,
                      label: 'Catatan (Opsional)',
                      hintText:
                          'Contoh: resep rumahan, pakai santan, tanpa gula',
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ManualMacroSection(
                title: 'Nutrisi Utama',
                subtitle:
                    'Kalau tidak tahu semua angka, isi yang tersedia dulu.',
                child: _ManualMacroGrid(
                  children: [
                    _ManualMacroNumberField(
                      controller: _caloriesController,
                      label: 'Kalori',
                      unit: 'kkal',
                    ),
                    _ManualMacroNumberField(
                      controller: _proteinController,
                      label: 'Protein',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _carbsController,
                      label: 'Karbohidrat',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _fatController,
                      label: 'Lemak Total',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _sugarController,
                      label: 'Gula',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _fiberController,
                      label: 'Serat',
                      unit: 'g',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ManualMacroSection(
                title: 'Lemak dan Mineral',
                subtitle:
                    'Bagian ini opsional, cocok kalau Anda punya data lebih lengkap.',
                child: _ManualMacroGrid(
                  children: [
                    _ManualMacroNumberField(
                      controller: _saturatedFatController,
                      label: 'Lemak Jenuh',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _monounsaturatedFatController,
                      label: 'Lemak Tak Jenuh Tunggal',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _polyunsaturatedFatController,
                      label: 'Lemak Tak Jenuh Ganda',
                      unit: 'g',
                    ),
                    _ManualMacroNumberField(
                      controller: _cholesterolController,
                      label: 'Kolesterol',
                      unit: 'mg',
                    ),
                    _ManualMacroNumberField(
                      controller: _calciumController,
                      label: 'Kalsium',
                      unit: 'mg',
                    ),
                    _ManualMacroNumberField(
                      controller: _portionGramsController,
                      label: 'Estimasi Gram',
                      unit: 'g',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ManualMacroSection(
                title: 'Referensi Opsional',
                subtitle: 'Boleh dikosongkan kalau tidak ada.',
                child: _ManualMacroTextField(
                  controller: _fdcFoodIdController,
                  label: 'FDC Food ID',
                  hintText: 'Contoh: 123456',
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _formError!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Konsumsi Lengkap',
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
      ),
    );
  }
}

class _MealCategoryOption {
  const _MealCategoryOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _ManualMacroInfoCard extends StatelessWidget {
  const _ManualMacroInfoCard({
    required this.typeLabel,
    required this.timeLabel,
  });

  final String typeLabel;
  final String timeLabel;

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
          const Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ManualMacroBadge(
                icon: Icons.restaurant_menu_rounded,
                label: typeLabel,
              ),
              _ManualMacroBadge(
                icon: Icons.access_time_rounded,
                label: timeLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualMacroBadge extends StatelessWidget {
  const _ManualMacroBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE64060)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualMacroSection extends StatelessWidget {
  const _ManualMacroSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ManualMacroGrid extends StatelessWidget {
  const _ManualMacroGrid({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        if (!isWide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 14) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ManualMacroTextField extends StatelessWidget {
  const _ManualMacroTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}

class _ManualMacroNumberField extends StatelessWidget {
  const _ManualMacroNumberField({
    required this.controller,
    required this.label,
    required this.unit,
  });

  final TextEditingController controller;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        suffixText: unit,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}
