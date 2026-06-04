import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

class DoctorPatientHeartRiskPage extends ConsumerStatefulWidget {
  const DoctorPatientHeartRiskPage({
    super.key,
    required this.patientId,
    this.entryData,
  });

  final String patientId;
  final DoctorHeartRiskEntryData? entryData;

  @override
  ConsumerState<DoctorPatientHeartRiskPage> createState() =>
      _DoctorPatientHeartRiskPageState();
}

class _DoctorPatientHeartRiskPageState
    extends ConsumerState<DoctorPatientHeartRiskPage> {
  DoctorHeartRiskAssessmentRecord? _latestAssessment;
  DoctorHeartRiskPredictionResult? _latestPrediction;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Object? _errorCause;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (!mounted) return;

    final hasData = _latestAssessment != null || _latestPrediction != null;

    setState(() {
      _isLoading = showLoader && !hasData;
      _isRefreshing = showLoader && hasData;
      _error = null;
      _errorCause = null;
    });

    try {
      final api = ref.read(doctorDashboardApiProvider);
      final results = await Future.wait([
        api.fetchLatestPatientHeartRiskAssessment(widget.patientId),
        api.fetchLatestPatientHeartRiskPrediction(widget.patientId),
      ]);

      if (!mounted) return;

      setState(() {
        _latestAssessment = results[0] as DoctorHeartRiskAssessmentRecord?;
        _latestPrediction = results[1] as DoctorHeartRiskPredictionResult?;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _errorCause = error;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _openAssessmentForm() async {
    final refreshed = await context.push<bool>(
      '/doctor/home/patients/${widget.patientId}/heart-risk-model/form',
      extra: widget.entryData,
    );

    if (refreshed == true) {
      await _loadData(showLoader: false);
      if (!mounted) return;
      AppToast.success(
        context,
        'Assessment tersimpan dan prediksi heart risk berhasil dijalankan.',
      );
    }
  }

  Future<void> _openHistoryPage() async {
    await context.push(
      '/doctor/home/patients/${widget.patientId}/heart-risk-model/history',
      extra: widget.entryData,
    );
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  String get _subtitle {
    final patient = widget.entryData?.patient;
    final fullName = _patientFullName(patient);
    return fullName.isEmpty ? 'Pasien Dashboard' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final showOfflinePage = _isNetworkError(_errorCause) &&
        !_isLoading &&
        _latestAssessment == null &&
        _latestPrediction == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Prediksi Heart Risk',
        subtitle: _subtitle,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssessmentForm,
        backgroundColor: const Color(0xFFE64060),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          'Isi Form Baru',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE64060),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _loadData(),
                color: const Color(0xFFE64060),
                backgroundColor: Colors.white,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    if (_isRefreshing)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xFFE64060),
                          backgroundColor: Color(0xFFFBCFD7),
                        ),
                      ),
                    if (showOfflinePage) ...[
                      const SizedBox(height: 14),
                      NoConnectionState.card(
                        title: 'Prediksi heart risk belum bisa dimuat',
                        message:
                            'Koneksi internet sedang bermasalah. Sambungkan lagi lalu tarik untuk memuat ulang.',
                        onRetry: () => _loadData(),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      if (_error != null &&
                          (_latestAssessment != null ||
                              _latestPrediction != null))
                        _DoctorHeartRiskWarningCard(
                          message: _error!,
                          onRetry: _loadData,
                        ),
                      _DoctorHeartRiskPredictionCard(
                        prediction: _latestPrediction,
                        onOpenHistory: _openHistoryPage,
                      ),
                      const SizedBox(height: 14),
                      _DoctorHeartRiskAssessmentCard(
                        assessment: _latestAssessment,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

String _patientFullName(DashboardPatient? patient) {
  if (patient == null) return '';

  final firstName = patient.firstName.trim();
  final lastName = patient.lastName.trim();
  return '$firstName $lastName'.trim();
}

class _DoctorHeartRiskPredictionCard extends StatelessWidget {
  const _DoctorHeartRiskPredictionCard({
    required this.prediction,
    required this.onOpenHistory,
  });

  final DoctorHeartRiskPredictionResult? prediction;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    if (prediction == null) {
      return _DoctorHeartRiskSectionCard(
        title: 'Prediksi Terbaru',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DoctorHeartRiskEmptyState(
              title: 'Belum ada prediksi heart risk',
              description:
                  'Isi form asesmen lalu jalankan prediksi dari tombol di kanan bawah untuk menampilkan hasil terbaru.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE13D5A),
                  side: const BorderSide(color: Color(0xFFF3A5B6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.history_rounded, size: 20),
                label: const Text(
                  'Lihat Riwayat Prediksi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final upstream = prediction!.upstream?.body;
    final probability = (upstream?.probability ?? 0).toDouble();
    final riskLevel = (upstream?.riskLevel ?? '').trim();
    final riskColor = _riskColor(riskLevel);

    return _DoctorHeartRiskSectionCard(
      title: 'Prediksi Terbaru',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  riskColor,
                  riskColor.withOpacity(0.78),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _riskLabel(riskLevel),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDateTime(prediction!.generatedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${(probability * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: probability.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.22),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                // const SizedBox(height: 10),
                // Text(
                //   'Threshold model ${(threshold * 100).toStringAsFixed(0)}%',
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 13,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Wrap(
          //   spacing: 12,
          //   runSpacing: 12,
          //   children: [
          //     _DoctorHeartRiskMetaChip(
          //       label: 'Generated',
          //       value: _formatDateTime(prediction!.generatedAt),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenHistory,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE13D5A),
                side: const BorderSide(color: Color(0xFFF3A5B6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 20),
              label: const Text(
                'Lihat Riwayat Prediksi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
      default:
        return const Color(0xFF16A34A);
    }
  }

  static String _riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'Risiko Tinggi';
      case 'medium':
        return 'Risiko Sedang';
      case 'low':
        return 'Risiko Rendah';
      default:
        return riskLevel.isEmpty ? 'Belum Diketahui' : riskLevel;
    }
  }
}

class _DoctorHeartRiskAssessmentCard extends StatelessWidget {
  const _DoctorHeartRiskAssessmentCard({
    required this.assessment,
  });

  final DoctorHeartRiskAssessmentRecord? assessment;

  @override
  Widget build(BuildContext context) {
    if (assessment == null) {
      return const _DoctorHeartRiskSectionCard(
        title: 'Assessment Terbaru',
        child: _DoctorHeartRiskEmptyState(
          title: 'Belum ada asesmen heart risk',
          description:
              'Gunakan tombol di kanan bawah untuk mengisi asesmen pertama pasien ini.',
        ),
      );
    }

    return _DoctorHeartRiskSectionCard(
      title: 'Asesmen Terbaru',
      child: Column(
        children: [
          _DoctorHeartRiskInfoRow(
            label: 'Tanggal Asesmen',
            value: _formatDateTime(assessment!.updatedAt),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Usia',
            value: assessment!.age?.toString() ?? '-',
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Jenis Kelamin',
            value: heartRiskEnumLabel('sex', assessment!.sex),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Jenis Nyeri Dada',
            value: heartRiskEnumLabel(
              'chest_pain_type',
              assessment!.chestPainType,
            ),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Tekanan Darah Sistolik',
            value: _numLabel(assessment!.restingBpS),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Gula Darah Puasa',
            value: heartRiskEnumLabel(
              'fasting_blood_sugar',
              assessment!.fastingBloodSugar,
            ),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Detak Jantung Maksimum',
            value: _numLabel(assessment!.maxHeartRate),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Angina Saat Aktivitas',
            value: heartRiskEnumLabel(
              'exercise_angina',
              assessment!.exerciseAngina,
            ),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Old Peak',
            value: _numLabel(assessment!.oldPeak),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Kemiringan ST',
            value: heartRiskEnumLabel('st_slope', assessment!.stSlope),
          ),
          _DoctorHeartRiskInfoRow(
            label: 'Diperbarui',
            value: _formatDateTime(assessment!.updatedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  static String _numLabel(num? value) {
    if (value == null) return '-';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class _DoctorHeartRiskWarningCard extends StatelessWidget {
  const _DoctorHeartRiskWarningCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function({bool showLoader}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sebagian data belum berhasil dimuat',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => onRetry(showLoader: false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: const Color(0xFF9A3412),
              ),
              child: const Text(
                'Coba Muat Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHeartRiskSectionCard extends StatelessWidget {
  const _DoctorHeartRiskSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
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

class _DoctorHeartRiskEmptyState extends StatelessWidget {
  const _DoctorHeartRiskEmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            color: Color(0xFF94A3B8),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorHeartRiskInfoRow extends StatelessWidget {
  const _DoctorHeartRiskInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year, $hour:$minute';
}
