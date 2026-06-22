import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/data/ml_mapping.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/ml_assessment/presentation/providers/ml_assessment_provider.dart';

class PatientMlAssessmentPage extends ConsumerStatefulWidget {
  const PatientMlAssessmentPage({super.key});

  @override
  ConsumerState<PatientMlAssessmentPage> createState() =>
      _PatientMlAssessmentPageState();
}

class _PatientMlAssessmentPageState
    extends ConsumerState<PatientMlAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int> _selectionValues = {};
  late final Map<String, TextEditingController> _rangeControllers;

  DateTime _assessmentDate = DateTime.now();
  String? _assessmentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rangeControllers = {
      for (final fieldKey in MlMapping.dynamic_form_mapping)
        if (_isRangeFieldKey(fieldKey)) fieldKey: TextEditingController(),
    };
    _resetAssessmentForm();
  }

  @override
  void dispose() {
    for (final controller in _rangeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static bool _isRangeFieldKey(String fieldKey) {
    final group = MlMapping.getGroupFromFieldKey(fieldKey);
    final codeId = MlMapping.getCodeIdFromFieldKey(fieldKey);
    if (group == null || codeId == null) return false;
    return MlMapping.isRange(group, codeId);
  }

  void _resetAssessmentForm() {
    _assessmentId = null;
    _assessmentDate = DateTime.now();
    _selectionValues.clear();
    for (final controller in _rangeControllers.values) {
      controller.clear();
    }
  }

  double? _toDoubleOrNull(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed;
  }

  String _formatApiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _submitAssessment() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      AppToast.warning(
        context,
        'Lengkapi semua pertanyaan yang wajib diisi dengan jawaban yang valid.',
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        'assessmentDate': _formatApiDate(_assessmentDate),
      };

      for (final fieldKey in MlMapping.dynamic_form_mapping) {
        final group = MlMapping.getGroupFromFieldKey(fieldKey);
        final codeId = MlMapping.getCodeIdFromFieldKey(fieldKey);
        if (group == null || codeId == null) continue;

        if (MlMapping.isSelection(group, codeId)) {
          final value = _selectionValues[fieldKey];
          if (value == null) {
            throw Exception('Semua pertanyaan wajib diisi.');
          }
          payload[fieldKey] = value;
        } else {
          final raw = _rangeControllers[fieldKey]!.text;
          final parsed = _toDoubleOrNull(raw);
          if (parsed == null) {
            throw Exception(
                'Semua pertanyaan wajib diisi dengan angka yang valid.');
          }
          payload[fieldKey] = parsed;
        }
      }

      final saved = await ref.read(mlAssessmentApiProvider).saveMlAssessment(
            assessmentId: _assessmentId,
            payload: payload,
          );

      if (!mounted) return;
      if (saved.isEmpty) {
        AppToast.error(context, 'Gagal menyimpan asesmen. Silakan coba lagi.');
        return;
      } else {
        context.pop();
        AppToast.success(context, 'Asesmen berhasil disimpan');
      }
      // Navigator.of(context).pop(saved.isNotEmpty);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE64060).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Color(0xFFE64060),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Asesmen ML',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Form dimulai kosong. Pilih jawaban yang sesuai untuk setiap pertanyaan.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              setState(_resetAssessmentForm);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE64060),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt().toString();
    }
    return asDouble.toStringAsFixed(2).replaceFirst(RegExp(r'\.0+$'), '');
  }

  Widget _buildFieldCard(String fieldKey) {
    final group = MlMapping.getGroupFromFieldKey(fieldKey);
    final codeId = MlMapping.getCodeIdFromFieldKey(fieldKey);
    if (group == null || codeId == null) return const SizedBox.shrink();

    final question = MlMapping.getQuestion(group, codeId) ?? fieldKey;
    final isSelection = MlMapping.isSelection(group, codeId);
    final options = MlMapping.getOptions(group, codeId);
    final rangeStart = MlMapping.getRangeStart(group, codeId);
    final rangeEnd = MlMapping.getRangeEnd(group, codeId);
    final rangeUnit = MlMapping.getRangeUnit(group, codeId);
    final allowDecimal = rangeStart != null && rangeEnd != null
        ? rangeStart % 1 != 0 || rangeEnd % 1 != 0
        : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (!isSelection && rangeStart != null && rangeEnd != null) ...[
            const SizedBox(height: 6),
            Text(
              'Rentang: ${_rangeLabel(rangeStart)} - ${_rangeLabel(rangeEnd)}${rangeUnit == null ? '' : ' $rangeUnit'}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isSelection)
            FormField<int>(
              initialValue: _selectionValues[fieldKey],
              validator: (value) {
                if (value == null) {
                  return 'Jawaban wajib dipilih';
                }
                return null;
              },
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: state.value,
                      isExpanded: true,
                      dropdownColor: const Color(0xFFF8FAFC),
                      hint: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pilih salah satu',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      decoration: InputDecoration(
                        // hintText: 'Pilih jawaban',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE64060)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFB91C1C)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFB91C1C)),
                        ),
                      ),
                      items: options.entries
                          .map(
                            (entry) => DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectionValues[fieldKey] = value ?? 0;
                        });
                        state.didChange(value);
                      },
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                );
              },
            )
          else
            TextFormField(
              controller: _rangeControllers[fieldKey],
              keyboardType: TextInputType.numberWithOptions(
                decimal: allowDecimal,
              ),
              decoration: InputDecoration(
                hintText: rangeStart != null && rangeEnd != null
                    ? '${_rangeLabel(rangeStart)} - ${_rangeLabel(rangeEnd)}${rangeUnit == null ? '' : ' $rangeUnit'}'
                    : null,
                hintStyle: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jawaban wajib diisi';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return 'Masukkan angka yang valid';
                }
                if (rangeStart != null && rangeEnd != null) {
                  if (parsed < rangeStart.toDouble() ||
                      parsed > rangeEnd.toDouble()) {
                    return 'Nilai harus berada di antara ${_rangeLabel(rangeStart)} dan ${_rangeLabel(rangeEnd)}${rangeUnit == null ? '' : ' $rangeUnit'}';
                  }
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Form Asesmen Pasien',
        subtitle: 'Isi form asesmen baru pasien',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    _buildHeaderCard(),
                    ...MlMapping.dynamic_form_mapping.map(
                      (fieldKey) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: _buildFieldCard(fieldKey),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'Menyimpan...' : 'Simpan Asesmen',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
