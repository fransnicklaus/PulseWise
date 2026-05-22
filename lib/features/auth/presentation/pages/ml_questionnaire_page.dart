import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/data/ml_mapping.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

class MlQuestionnairePage extends ConsumerStatefulWidget {
  final String token;
  final String patientId;

  const MlQuestionnairePage({
    super.key,
    required this.token,
    required this.patientId,
  });

  @override
  ConsumerState<MlQuestionnairePage> createState() =>
      _MlQuestionnairePageState();
}

class _MlQuestionnairePageState extends ConsumerState<MlQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int> _answers = {};
  bool _isSubmitting = false;
  bool _isInitialLoading = true;

  void _goHomeSafely() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExistingMlProfile();
  }

  Future<void> _loadExistingMlProfile() async {
    if (!mounted) return;

    setState(() => _isInitialLoading = true);
    try {
      final existing = await ref.read(profileApiProvider).fetchMlProfile(
            token: widget.token,
            patientId: widget.patientId,
          );

      if (!mounted) return;

      final parsedAnswers = <String, int>{};
      for (final fieldKey in MlMapping.form_mapping) {
        final rawValue = existing[fieldKey];
        final parsed = _toIntOrNull(rawValue);
        if (parsed == null) continue;

        final group = MlMapping.getGroupFromFieldKey(fieldKey);
        final codeId = MlMapping.getCodeIdFromFieldKey(fieldKey);
        if (group == null || codeId == null) continue;

        final validOptions = MlMapping.getOptions(group, codeId);
        if (!validOptions.containsKey(parsed)) continue;

        parsedAnswers[fieldKey] = parsed;
      }

      if (!mounted) return;
      setState(() {
        _answers
          ..clear()
          ..addAll(parsedAnswers);
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.warning(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Future<void> _submitMlProfile() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{};
      for (final fieldKey in MlMapping.form_mapping) {
        final answer = _answers[fieldKey];
        if (answer == null) {
          throw Exception('Semua pertanyaan wajib diisi.');
        }
        payload[fieldKey] = answer;
      }

      await ref.read(profileApiProvider).submitMlProfile(
            token: widget.token,
            patientId: widget.patientId,
            payload: payload,
          );

      if (!mounted) return;
      ref.read(healthConnectLoginPromptArmedProvider.notifier).state = true;
      _goHomeSafely();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildQuestionField(String fieldKey, int index) {
    final group = MlMapping.getGroupFromFieldKey(fieldKey);
    final codeId = MlMapping.getCodeIdFromFieldKey(fieldKey);

    if (group == null || codeId == null || !MlMapping.hasCode(group, codeId)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          'Konfigurasi form tidak valid untuk: $fieldKey',
          style: const TextStyle(
            color: Color(0xFF991B1B),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final question = MlMapping.getQuestion(group, codeId) ?? fieldKey;
    final options = MlMapping.getOptions(group, codeId);

    final orderedKeys = options.keys.toList()..sort((a, b) => a.compareTo(b));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $question',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _answers[fieldKey],
            isExpanded: true,
            alignment: AlignmentDirectional.centerStart,
            dropdownColor: Colors.white,
            iconEnabledColor: const Color(0xFF64748B),
            decoration: InputDecoration(
              hintText: 'Pilih jawaban',
              hintStyle: const TextStyle(
                fontSize: 18,
                color: Color(0xFF334155),
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
            items: orderedKeys
                .map(
                  (key) => DropdownMenuItem<int>(
                    value: key,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      options[key] ?? key.toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                if (value == null) {
                  _answers.remove(fieldKey);
                } else {
                  _answers[fieldKey] = value;
                }
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Jawaban wajib dipilih';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFFE64060),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Menyiapkan Kuisioner',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kami sedang memuat jawaban terakhir Anda agar bisa langsung diperbarui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Kuisioner Pasien',
        subtitle: 'Isi untuk kebutuhan prediksi kesehatan',
        showBackButton: true,
        onBackPressed: _goHomeSafely,
      ),
      body: SafeArea(
        child: _isInitialLoading
            ? _buildLoadingScreen()
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        children: [
                          ...MlMapping.form_mapping.asMap().entries.map(
                              (entry) =>
                                  _buildQuestionField(entry.value, entry.key)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitMlProfile,
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
                              : const Icon(FluentIcons.send_24_regular,
                                  size: 20),
                          label: Text(
                            _isSubmitting ? 'Menyimpan...' : 'Kirim Kuisioner',
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
