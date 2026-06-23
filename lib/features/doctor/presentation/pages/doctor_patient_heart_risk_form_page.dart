import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';

class DoctorPatientHeartRiskFormPage extends ConsumerStatefulWidget {
  const DoctorPatientHeartRiskFormPage({
    super.key,
    required this.patientId,
    this.entryData,
  });

  final String patientId;
  final DoctorHeartRiskEntryData? entryData;

  @override
  ConsumerState<DoctorPatientHeartRiskFormPage> createState() =>
      _DoctorPatientHeartRiskFormPageState();
}

class _DoctorPatientHeartRiskFormPageState
    extends ConsumerState<DoctorPatientHeartRiskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _restingBpController = TextEditingController();
  final _maxHeartRateController = TextEditingController();
  final _oldPeakController = TextEditingController();

  DateTime _assessmentDate = DateTime.now();
  String? _assessmentId;
  String? _sex;
  String? _chestPainType;
  String? _fastingBloodSugar;
  String? _exerciseAngina;
  String? _stSlope;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ageController.dispose();
    _restingBpController.dispose();
    _maxHeartRateController.dispose();
    _oldPeakController.dispose();
    super.dispose();
  }

  Future<void> _pickAssessmentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;
    setState(() => _assessmentDate = picked);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  int? _parseRequiredInt(String raw) {
    return int.tryParse(raw.trim());
  }

  num? _parseRequiredNum(String raw) {
    return num.tryParse(raw.trim());
  }

  dynamic _normalizeNumber(num value) {
    return value == value.roundToDouble() ? value.toInt() : value.toDouble();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _autoValidateMode = AutovalidateMode.always;
    });

    final valid = _formKey.currentState?.validate() ?? false;
    final hasChoiceValidationErrors = _sex == null ||
        _chestPainType == null ||
        _fastingBloodSugar == null ||
        _exerciseAngina == null ||
        _stSlope == null;
    if (!valid || hasChoiceValidationErrors) return;

    final age = _parseRequiredInt(_ageController.text);
    final restingBp = _parseRequiredNum(_restingBpController.text);
    final maxHeartRate = _parseRequiredNum(_maxHeartRateController.text);
    final oldPeak = _parseRequiredNum(_oldPeakController.text);

    if (age == null ||
        restingBp == null ||
        maxHeartRate == null ||
        oldPeak == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(doctorDashboardApiProvider);
      final savedAssessment = await api.savePatientHeartRiskAssessment(
        widget.patientId,
        assessmentId: _assessmentId,
        payload: {
          'assessmentDate': _formatDate(_assessmentDate),
          'age': age,
          'sex': _sex,
          'chest_pain_type': _chestPainType,
          'resting_bp_s': _normalizeNumber(restingBp),
          'fasting_blood_sugar': _fastingBloodSugar,
          'max_heart_rate': _normalizeNumber(maxHeartRate),
          'exercise_angina': _exerciseAngina,
          'old_peak': _normalizeNumber(oldPeak),
          'st_slope': _stSlope,
        },
      );

      _assessmentId = savedAssessment.assessmentId.isEmpty
          ? _assessmentId
          : savedAssessment.assessmentId;

      final readiness =
          await api.fetchPatientHeartRiskReadiness(widget.patientId);
      if (!mounted) return;

      if (!readiness.ready) {
        await _showMissingFieldsSheet(readiness.missingFields);
        return;
      }

      await api.runPatientHeartRiskPrediction(
        widget.patientId,
        includePayload: true,
      );

      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showMissingFieldsSheet(List<String> missingFields) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final displayFields = missingFields.isEmpty
            ? const <String>['Field readiness belum lengkap']
            : missingFields.map(_formatMissingFieldLabel).toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    'Prediksi belum bisa dijalankan',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assessment sudah tersimpan, tapi model belum ready. Lengkapi field berikut lalu coba jalankan lagi.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayFields
                        .map(
                          (field) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFED7AA),
                              ),
                            ),
                            child: Text(
                              field,
                              style: const TextStyle(
                                color: Color(0xFF9A3412),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMissingFieldLabel(String raw) {
    const fieldLabels = {
      'age': 'Age',
      'sex': 'Sex',
      'chest_pain_type': 'Chest Pain Type',
      'resting_bp_s': 'Resting BP S',
      'fasting_blood_sugar': 'Fasting Blood Sugar',
      'max_heart_rate': 'Max Heart Rate',
      'exercise_angina': 'Exercise Angina',
      'old_peak': 'Old Peak',
      'st_slope': 'ST Slope',
    };

    final normalized = raw.trim();
    return fieldLabels[normalized] ?? normalized.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Form Heart Risk',
        subtitle: 'Lengkapi second ML assessment pasien',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    // const _DoctorHeartRiskFormIntroCard(),
                    const SizedBox(height: 14),
                    _DoctorHeartRiskFormSection(
                      title: 'Tanggal Asesmen',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickAssessmentDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFFE64060),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDate(_assessmentDate),
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _DoctorHeartRiskFormSection(
                      title: 'Field Wajib',
                      child: Column(
                        children: [
                          _DoctorHeartRiskTextField(
                            controller: _ageController,
                            label: 'Usia',
                            hint: 'Contoh: 58',
                            helperText: 'Usia pasien saat asesmen dijalankan.',
                            keyboardType:
                                const TextInputType.numberWithOptions(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Usia wajib diisi';
                              }
                              if (_parseRequiredInt(value) == null) {
                                return 'Usia harus berupa angka bulat';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskChoiceField(
                            label: 'Jenis Kelamin',
                            helperText: 'Pilih jenis kelamin pasien.',
                            value: _sex,
                            errorText:
                                _autoValidateMode == AutovalidateMode.always &&
                                        _sex == null
                                    ? 'Pilih jenis kelamin terlebih dahulu'
                                    : null,
                            options: sexLabels,
                            onChanged: (value) {
                              setState(() => _sex = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskChoiceField(
                            label: 'Jenis Nyeri Dada',
                            helperText:
                                'Pilih jenis keluhan nyeri dada pasien.',
                            value: _chestPainType,
                            errorText:
                                _autoValidateMode == AutovalidateMode.always &&
                                        _chestPainType == null
                                    ? 'Pilih jenis nyeri dada terlebih dahulu'
                                    : null,
                            options: chestPainTypeLabels,
                            onChanged: (value) {
                              setState(() => _chestPainType = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskTextField(
                            controller: _restingBpController,
                            label: 'Tekanan Darah Sistolik',
                            hint: 'Contoh: 151',
                            helperText:
                                'Tekanan darah sistolik pasien saat istirahat.',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tekanan darah sistolik wajib diisi';
                              }
                              if (_parseRequiredNum(value) == null) {
                                return 'Tekanan darah sistolik harus berupa angka';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskChoiceField(
                            label: 'Gula Darah Puasa',
                            helperText:
                                'Pilih kategori gula darah puasa pasien.',
                            value: _fastingBloodSugar,
                            errorText: _autoValidateMode ==
                                        AutovalidateMode.always &&
                                    _fastingBloodSugar == null
                                ? 'Pilih kategori gula darah puasa terlebih dahulu'
                                : null,
                            options: fastingBloodSugarLabels,
                            onChanged: (value) {
                              setState(() => _fastingBloodSugar = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskTextField(
                            controller: _maxHeartRateController,
                            label: 'Detak Jantung Maksimum',
                            hint: 'Contoh: 118',
                            helperText: 'Detak jantung maksimum pasien.',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Detak jantung maksimum wajib diisi';
                              }
                              if (_parseRequiredNum(value) == null) {
                                return 'Detak jantung maksimum harus berupa angka';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskChoiceField(
                            label: 'Angina Saat Aktivitas',
                            helperText:
                                'Apakah pasien mengalami exercise angina?',
                            value: _exerciseAngina,
                            errorText: _autoValidateMode ==
                                        AutovalidateMode.always &&
                                    _exerciseAngina == null
                                ? 'Pilih kondisi angina saat aktivitas terlebih dahulu'
                                : null,
                            options: exerciseAnginaLabels,
                            onChanged: (value) {
                              setState(() => _exerciseAngina = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskTextField(
                            controller: _oldPeakController,
                            label: 'Old Peak',
                            hint: 'Contoh: 0.5',
                            helperText: 'Nilai old peak dapat berupa desimal.',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Old peak wajib diisi';
                              }
                              if (_parseRequiredNum(value) == null) {
                                return 'Old peak harus berupa angka';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _DoctorHeartRiskChoiceField(
                            label: 'Kemiringan ST',
                            helperText:
                                'Pilih bentuk kemiringan segmen ST pasien.',
                            value: _stSlope,
                            errorText:
                                _autoValidateMode == AutovalidateMode.always &&
                                        _stSlope == null
                                    ? 'Pilih kemiringan ST terlebih dahulu'
                                    : null,
                            options: stSlopeLabels,
                            onChanged: (value) {
                              setState(() => _stSlope = value);
                            },
                          ),
                        ],
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
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                        : const Icon(Icons.auto_graph_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Menyimpan...'
                          : 'Simpan dan Jalankan Prediksi',
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

// class _DoctorHeartRiskFormIntroCard extends StatelessWidget {
//   const _DoctorHeartRiskFormIntroCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF5F7),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: const Color(0xFFFBCFD7)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: const Color(0xFFE64060).withOpacity(0.12),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(
//               Icons.edit_note_rounded,
//               color: Color(0xFFE64060),
//             ),
//           ),
//           const SizedBox(width: 14),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Lengkapi Assessment Heart Risk',
//                   style: TextStyle(
//                     color: Color(0xFF0F172A),
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 SizedBox(height: 6),
//                 Text(
//                   'Form ini selalu dimulai dari kosong. Setelah assessment disimpan, aplikasi akan mengecek readiness model sebelum menjalankan prediksi.',
//                   style: TextStyle(
//                     color: Color(0xFF64748B),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     height: 1.45,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _DoctorHeartRiskFormSection extends StatelessWidget {
  const _DoctorHeartRiskFormSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DoctorHeartRiskTextField extends StatelessWidget {
  const _DoctorHeartRiskTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helperText,
    required this.validator,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String helperText;
  final String? Function(String?) validator;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helperText,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
    );
  }
}

class _DoctorHeartRiskChoiceField extends StatelessWidget {
  const _DoctorHeartRiskChoiceField({
    required this.label,
    required this.helperText,
    required this.value,
    required this.errorText,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String helperText;
  final String? value;
  final String? errorText;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            alignment: AlignmentDirectional.centerStart,
            dropdownColor: const Color(0xFFF8FAFC),
            hint: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih salah satu',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              errorText: hasError ? errorText : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE64060)),
              ),
            ),
            items: options.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
          ),
        ],
      ),
    );
  }
}
