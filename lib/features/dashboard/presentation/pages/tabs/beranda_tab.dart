import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/app_connectivity_provider.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/utils/medication_status_ui.dart';
import 'package:pulsewise/features/dashboard/presentation/widgets/medication_status_bottom_sheet.dart';

final latestMlRecommendationProvider =
    FutureProvider<MlRecommendationResponse?>((ref) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchLatestMlRecommendation();
});

class BerandaTab extends ConsumerStatefulWidget {
  const BerandaTab({super.key});

  @override
  ConsumerState<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends ConsumerState<BerandaTab>
    with AutomaticKeepAliveClientMixin {
  static const double _healthStatusContentHeight = 248;

  @override
  bool get wantKeepAlive => true;

  int _healthStatusIndex = 0;
  final int _healthStatusCount = 2;

  void _previousTab() {
    setState(() {
      _healthStatusIndex =
          (_healthStatusIndex - 1 + _healthStatusCount) % _healthStatusCount;
    });
  }

  void _nextTab() {
    setState(() {
      _healthStatusIndex = (_healthStatusIndex + 1) % _healthStatusCount;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Swipe right (previous tab)
    if (details.primaryVelocity! > 0 && _healthStatusIndex > 0) {
      _previousTab();
    }
    // Swipe left (next tab)
    else if (details.primaryVelocity! < 0 &&
        _healthStatusIndex < _healthStatusCount - 1) {
      _nextTab();
    }
  }

  String _networkFailureMessage({
    required String fallbackMessage,
  }) {
    final connectivity = ref.read(appConnectivityProvider);
    if (connectivity.isOffline || !connectivity.hasNetworkTransport) {
      return connectivity.message;
    }
    return fallbackMessage;
  }

  Future<void> _onRefresh() async {
    final connectivity = ref.read(appConnectivityProvider);
    if (connectivity.isOffline) {
      AppToast.warning(context, connectivity.message);
      return;
    }

    try {
      await Future.wait([
        ref.refresh(authMeProvider.future),
        ref.refresh(latestMlRecommendationProvider.future),
        ref.refresh(quickDashboardProvider.future),
        ref.refresh(medicationCalendarRangeProvider(
          MedicationCalendarRangeQuery(
            from: DateTime.now(),
            to: DateTime.now().add(const Duration(days: 2)),
          ),
        ).future),
      ]);
    } catch (e) {
      if (!mounted) return;
      if (isNetworkRequestError(e)) {
        AppToast.warning(
          context,
          _networkFailureMessage(
            fallbackMessage:
                'Koneksi internet bermasalah. Beranda belum bisa dimuat ulang.',
          ),
        );
        return;
      }
      rethrow;
    }
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  // String _healthStatusTabLabel() {
  //   if (_healthStatusIndex == 0) return 'Latest Recommendation';
  //   return 'Latest BMI';
  // }

  Widget _buildHealthStatusContent({
    required AsyncValue<MlRecommendationResponse?> latestRecommendation,
    required AsyncValue<QuickDashboardResponse?> quickDashboard,
  }) {
    if (_healthStatusIndex == 0) {
      return _buildLatestRecommendationTab(
          latestRecommendation, quickDashboard);
    }
    return _buildLatestVitalsTab(quickDashboard);
  }

  Widget _buildLatestRecommendationTab(
    AsyncValue<MlRecommendationResponse?> latestRecommendation,
    AsyncValue<QuickDashboardResponse?> quickDashboard,
  ) {
    return latestRecommendation.when(
      data: (rec) {
        final rawRisk =
            rec?.data?.upstream?.body?.recommendationResult.currentRisk;
        final hasRisk = rawRisk != null;
        final risk =
            hasRisk ? rawRisk.toDouble().clamp(0, 100).toDouble() : 0.0;
        final progress = hasRisk ? (risk / 100).clamp(0.0, 1.0) : 0.0;
        final riskText = hasRisk ? '${risk.toStringAsFixed(1)}%' : '';
        final riskStyle = hasRisk
            ? _riskStyleForScore(risk)
            : const _RiskStyle(
                accentColor: Color(0xFFE64060),
                backgroundColor: Color(0xFFFFF7F8),
                borderColor: Color(0xFFFFD6DD),
              );

        final topCard = SizedBox(
          height: 96,
          child: Container(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color:
                  hasRisk ? riskStyle.backgroundColor : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    hasRisk ? riskStyle.borderColor : const Color(0xFFE2E8F0),
              ),
            ),
            child: hasRisk
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Risiko Eksisting',
                              style: TextStyle(
                                color: Color(0xFF525252),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            riskText,
                            style: TextStyle(
                              color: riskStyle.accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 11,
                          value: progress,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            riskStyle.accentColor,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.expand(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Belum ada rekomendasi terbaru',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Jalankan prediksi kesehatan untuk melihat ringkasan risiko Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topCard,
            const SizedBox(height: 12),
            quickDashboard.when(
              data: (dashResponse) {
                final dashboardData = dashResponse?.data;
                return _buildRecommendationVitalsRow(dashboardData);
              },
              loading: () => _buildRecommendationVitalsRow(null),
              error: (_, __) => _buildRecommendationVitalsRow(null),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(color: Color(0xFFE64060)),
        ),
      ),
      error: (_, __) => const _HealthStatusEmptyState(
        title: 'Gagal memuat rekomendasi',
        subtitle: 'Tarik ke bawah untuk memuat ulang.',
      ),
    );
  }

  Widget _buildRecommendationVitalsRow(QuickDashboardData? dashboardData) {
    final bloodPressure = _bloodPressureValue(dashboardData);
    final heartRate = _fieldValue(dashboardData, 'heartRate');
    final bloodPressureMeasuredAt = _bloodPressureMeasuredAt(dashboardData);
    final heartRateMeasuredAt = _fieldMeasuredAt(dashboardData, 'heartRate');

    return Row(
      children: [
        Expanded(
          child: _buildSmallVitalCard(
            label: 'Tekanan Darah',
            value: bloodPressure ?? '-',
            unit: 'mmHg',
            icon: Icons.favorite_outline,
            bgColor: const Color(0xFFF7FAFF),
            borderColor: const Color(0xFFD7E5FF),
            iconBg: const Color(0xFF285DBE),
            latestMeasuredAt: bloodPressureMeasuredAt,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallVitalCard(
            label: 'Detak Jantung',
            value: heartRate != null ? heartRate.toStringAsFixed(0) : '-',
            unit: 'BPM',
            icon: Icons.favorite,
            bgColor: const Color(0xFFFFF7F8),
            borderColor: const Color(0xFFFFD6DD),
            iconBg: const Color(0xFFE64060),
            latestMeasuredAt: heartRateMeasuredAt,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallVitalCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required DateTime? latestMeasuredAt,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconBg,
                  size: 16,
                ),
              ),
              Tooltip(
                message: _metricMeasureTooltipMessage(
                  label: label,
                  measuredAt: latestMeasuredAt,
                ),
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                verticalOffset: 10,
                waitDuration: Duration.zero,
                showDuration: const Duration(seconds: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor.withOpacity(0.9),
                    ),
                  ),
                  child: const Icon(
                    FluentIcons.info_12_regular,
                    color: Color(0xFF64748B),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF525252),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestVitalsTab(AsyncValue<QuickDashboardResponse?> quickDash) {
    return quickDash.when(
      data: (dashResponse) {
        final dashboardData = dashResponse?.data;
        final oxygenSaturation = _fieldValue(dashboardData, 'oxygenSaturation');
        final weight = _fieldValue(dashboardData, 'weight');
        final latestMeasuredAt = _latestDashboardMeasuredAt(dashboardData);

        return Column(
          children: [
            // Row 1: O2 + Weight
            Row(
              children: [
                Expanded(
                  child: _buildSmallVitalCard(
                    label: 'Oksigen Jenuh',
                    value: oxygenSaturation != null
                        ? oxygenSaturation.toStringAsFixed(0)
                        : '-',
                    unit: '%',
                    icon: Icons.air,
                    bgColor: const Color(0xFFF0F9FF),
                    borderColor: const Color(0xFFCFF0FF),
                    iconBg: const Color(0xFF0EA5E9),
                    latestMeasuredAt:
                        _fieldMeasuredAt(dashboardData, 'oxygenSaturation'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSmallVitalCard(
                    label: 'Berat Badan',
                    value: weight != null ? weight.toStringAsFixed(1) : '-',
                    unit: 'kg',
                    icon: Icons.monitor_weight_outlined,
                    bgColor: const Color(0xFFFFF8F0),
                    borderColor: const Color(0xFFFFD99B),
                    iconBg: const Color(0xFFFFA726),
                    latestMeasuredAt: _fieldMeasuredAt(dashboardData, 'weight'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: Measured Time (full width)
            SizedBox(
              height: 96,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FFF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCDF3D5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9744).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF2D9744),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Waktu Pengukuran',
                            style: TextStyle(
                              color: Color(0xFF525252),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latestMeasuredAt != null
                                ? _formatMeasuredTime(latestMeasuredAt)
                                : '-',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(color: Color(0xFFE64060)),
        ),
      ),
      error: (_, __) => const _HealthStatusEmptyState(
        title: 'Gagal memuat vitals',
        subtitle: 'Tarik ke bawah untuk memuat ulang.',
      ),
    );
  }

  num? _fieldValue(QuickDashboardData? data, String fieldKey) {
    final fieldMeasurement = data?.latestVitalsByField[fieldKey]?.value;
    if (fieldMeasurement != null) {
      return fieldMeasurement;
    }

    final vitals = data?.latestVitals;
    switch (fieldKey) {
      case 'systolicBp':
        return vitals?.systolicBp;
      case 'diastolicBp':
        return vitals?.diastolicBp;
      case 'heartRate':
        return vitals?.heartRate;
      case 'oxygenSaturation':
        return vitals?.oxygenSaturation;
      case 'weight':
        return vitals?.weight;
      case 'height':
        return vitals?.height;
      case 'bmi':
        return vitals?.bmi;
      default:
        return null;
    }
  }

  DateTime? _fieldMeasuredAt(QuickDashboardData? data, String fieldKey) {
    final rawMeasuredAt = data?.latestVitalsByField[fieldKey]?.measuredAt;
    if (rawMeasuredAt != null && rawMeasuredAt.isNotEmpty) {
      return DateTime.tryParse(rawMeasuredAt)?.toLocal();
    }
    return null;
  }

  String? _bloodPressureValue(QuickDashboardData? data) {
    final systolic = _fieldValue(data, 'systolicBp');
    final diastolic = _fieldValue(data, 'diastolicBp');
    if (systolic == null && diastolic == null) {
      return null;
    }
    final systolicText = systolic?.toStringAsFixed(0) ?? '-';
    final diastolicText = diastolic?.toStringAsFixed(0) ?? '-';
    return '$systolicText/$diastolicText';
  }

  DateTime? _bloodPressureMeasuredAt(QuickDashboardData? data) {
    final systolicMeasuredAt = _fieldMeasuredAt(data, 'systolicBp');
    final diastolicMeasuredAt = _fieldMeasuredAt(data, 'diastolicBp');
    if (systolicMeasuredAt == null) return diastolicMeasuredAt;
    if (diastolicMeasuredAt == null) return systolicMeasuredAt;
    return systolicMeasuredAt.isAfter(diastolicMeasuredAt)
        ? systolicMeasuredAt
        : diastolicMeasuredAt;
  }

  String _metricMeasureTooltipMessage({
    required String label,
    required DateTime? measuredAt,
  }) {
    if (measuredAt == null) {
      return '$label\nBelum ada data pengukuran terbaru.';
    }
    return '$label\nTerakhir diukur pada ${_formatMeasuredTime(measuredAt)}.';
  }

  DateTime? _latestDashboardMeasuredAt(QuickDashboardData? data) {
    final fieldDates = data?.latestVitalsByField.values
            .map((entry) => entry.measuredAt)
            .whereType<String>()
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .toList() ??
        const <DateTime>[];

    if (fieldDates.isNotEmpty) {
      fieldDates.sort((a, b) => b.compareTo(a));
      return fieldDates.first.toLocal();
    }

    final fallback = data?.latestVitals?.measuredAt;
    if (fallback != null && fallback.isNotEmpty) {
      return DateTime.tryParse(fallback)?.toLocal();
    }
    return null;
  }

  String _formatMeasuredTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    return '${dateTime.day} $month ${dateTime.year} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authMe = ref.watch(authMeProvider);
    final firstName = authMe.maybeWhen(
      data: (user) => user.firstName.trim(),
      orElse: () => '',
    );
    final greetingName = firstName.isEmpty ? 'Halo' : 'Halo, $firstName';

    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, now.day);
    final toDate = DateTime(now.year, now.month, now.day + 2);
    final calendarQuery = MedicationCalendarRangeQuery(
      from: fromDate,
      to: toDate,
    );
    final upcomingMedicationAsync =
        ref.watch(medicationCalendarRangeProvider(calendarQuery));
    final latestRecommendationAsync = ref.watch(latestMlRecommendationProvider);
    final quickDashboardAsync = ref.watch(quickDashboardProvider);
    double topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFE64060),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            // Red gradient background header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.2, -2.5),
                      end: Alignment(0.8, 0.5),
                      colors: [
                        Color(0xFFE64060),
                        Color(0xFFFFADB5),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable content
            Column(
              children: [
                SizedBox(height: topPadding),
                // App Bar / Header content
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrentDate(),
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF04666).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          FluentIcons.alert_24_regular,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Emergency Contact Card
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    context.push('/home/contacts');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      // gradient: const LinearGradient(
                      //   colors: [
                      //     Color(0xFFE64060),
                      //     Color(0xFFFF7E93),
                      //     Color(0xFFE64060)
                      //   ],
                      //   begin: Alignment.centerLeft,
                      //   end: Alignment.centerRight,
                      // ),
                      color: const Color(0xFFE64060),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          offset: Offset(0, 10),
                          blurRadius: 23,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 244, 184, 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Color(0xFFFFFFFF),
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kontak Darurat',
                                style: TextStyle(
                                  color: Color(0xFFFFF4B8),
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tekan untuk menghubungi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          FluentIcons.info_24_regular,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                // Health Status Overview Button
                const SizedBox(height: 24),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 24),
                //   child: GestureDetector(
                //     onTap: () {
                //       context.push('/home/patient-dashboard');
                //     },
                //     child: Container(
                //       padding: const EdgeInsets.all(20),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(24),
                //         border: Border.all(color: const Color(0xFFE2E8F0)),
                //         boxShadow: const [
                //           BoxShadow(
                //             color: Color.fromRGBO(0, 0, 0, 0.03),
                //             offset: Offset(0, 7),
                //             blurRadius: 33.3,
                //           ),
                //         ],
                //       ),
                //       child: Row(
                //         children: [
                //           Container(
                //             width: 50,
                //             height: 50,
                //             decoration: BoxDecoration(
                //               color: const Color.fromRGBO(240, 70, 102, 0.1),
                //               borderRadius: BorderRadius.circular(14),
                //             ),
                //             child: const Icon(
                //               Icons.favorite,
                //               color: Color(0xFFE64060),
                //             ),
                //           ),
                //           const SizedBox(width: 16),
                //           const Expanded(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   'Status Kesehatan',
                //                   style: TextStyle(
                //                     color: Color(0xFF1A202C),
                //                     fontSize: 18,
                //                     fontWeight: FontWeight.w600,
                //                   ),
                //                 ),
                //                 SizedBox(height: 4),
                //                 Text(
                //                   'Lihat dashboard metrik',
                //                   style: TextStyle(
                //                     color: Color(0xFF62748E),
                //                     fontSize: 13,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //           Container(
                //             width: 36,
                //             height: 36,
                //             decoration: BoxDecoration(
                //               color: const Color(0xFFF1F5F9),
                //               borderRadius: BorderRadius.circular(10),
                //             ),
                //             child: const Icon(
                //               Icons.arrow_forward_ios,
                //               color: Color(0xFF525252),
                //               size: 16,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                GestureDetector(
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          offset: Offset(0, 7),
                          blurRadius: 33.3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Carousel Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  // Container(
                                  //   width: 50,
                                  //   height: 50,
                                  //   decoration: BoxDecoration(
                                  //     color: const Color.fromRGBO(
                                  //         240, 70, 102, 0.1),
                                  //     borderRadius: BorderRadius.circular(14),
                                  //   ),
                                  //   child: const Icon(
                                  //     Icons.favorite,
                                  //     color: Color(0xFFE64060),
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Status Kesehatan',
                                          style: TextStyle(
                                            color: Color(0xFF525252),
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Status kesehatan terbaru',
                                          style: const TextStyle(
                                            color: Color(0xFF62748E),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    context.push('/home/patient-dashboard');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE64060),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Detail',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Animated Health Metrics
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.3, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox(
                            key: ValueKey(_healthStatusIndex),
                            width: double.infinity,
                            height: _healthStatusContentHeight,
                            child: _buildHealthStatusContent(
                              latestRecommendation: latestRecommendationAsync,
                              quickDashboard: quickDashboardAsync,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bottom navigation: arrows + dots in one row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap:
                                  _healthStatusIndex == 0 ? null : _previousTab,
                              child: Container(
                                width: 36,
                                height: 36,
                                // decoration: BoxDecoration(
                                //   color: _healthStatusIndex == 0
                                //       ? const Color(0xFFE8EAED)
                                //       : const Color(0xFFF1F5F9),
                                //   borderRadius: BorderRadius.circular(10),
                                // ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: _healthStatusIndex == 0
                                      ? const Color(0xFFBFBFBF)
                                      : const Color(0xFF525252),
                                  size: 20,
                                ),
                              ),
                            ),
                            // Dots indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(_healthStatusCount, (index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: index == _healthStatusIndex ? 31 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: index == _healthStatusIndex
                                          ? const Color(0xFFE74665)
                                          : const Color(0xFFCAD5E2),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            GestureDetector(
                              onTap:
                                  _healthStatusIndex == _healthStatusCount - 1
                                      ? null
                                      : _nextTab,
                              child: Container(
                                width: 36,
                                height: 36,
                                // decoration: BoxDecoration(
                                //   color: _healthStatusIndex ==
                                //           _healthStatusCount - 1
                                //       ? const Color(0xFFE8EAED)
                                //       : const Color(0xFFF1F5F9),
                                //   borderRadius: BorderRadius.circular(10),
                                // ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: _healthStatusIndex ==
                                          _healthStatusCount - 1
                                      ? const Color(0xFFBFBFBF)
                                      : const Color(0xFF525252),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildUpcomingMedicationSection(
                    context, upcomingMedicationAsync, calendarQuery),

                // Menu Utama header
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Menu Utama',
                      style: TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Diari Kesehatan Full Width Button
                GestureDetector(
                  onTap: () {
                    // context.push('/home/diary');
                    ref.read(dashboardNavIndexProvider.notifier).state = 2;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 59,
                          height: 59,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE64060),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DIARI KESEHATAN',
                                style: TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Catat semua kondisi harian Anda',
                                style: TextStyle(
                                  color: Color(0xFFCD3754),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Half Width Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Edukasi Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(dashboardNavIndexProvider.notifier).state =
                                1;
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 59,
                                  height: 59,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    FluentIcons.book_open_24_regular,
                                    color: Color(0xFF6C2BD9),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Edukasi',
                                  style: TextStyle(
                                    color: Color(0xFF525252),
                                    fontSize: 18,
                                  ),
                                ),
                                const Text(
                                  'Artikel Kesehatan',
                                  style: TextStyle(
                                    color: Color(0xFF62748E),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pengingat Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(dashboardNavIndexProvider.notifier).state =
                                3;
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 59,
                                  height: 59,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    FluentIcons.alert_24_regular,
                                    color: Color(0xFFE08B3D),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Pengingat',
                                  style: TextStyle(
                                    color: Color(0xFF525252),
                                    fontSize: 18,
                                  ),
                                ),
                                const Text(
                                  'Obat & Jadwal',
                                  style: TextStyle(
                                    color: Color(0xFF62748E),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMedicationSection(
    BuildContext context,
    AsyncValue<MedicationCalendarResponse> asyncValue,
    MedicationCalendarRangeQuery query,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengingat Obat',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Obat terdekat dalam 3 hari ke depan',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            asyncValue.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(
                    color: Color(0xFFE64060),
                  ),
                ),
              ),
              error: (error, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              data: (response) {
                final items = [...response.items]..sort((a, b) {
                    final dateA = a.scheduledDate ?? DateTime(1970);
                    final dateB = b.scheduledDate ?? DateTime(1970);
                    final dateCompare = dateA.compareTo(dateB);
                    if (dateCompare != 0) return dateCompare;
                    return a.scheduledTime.compareTo(b.scheduledTime);
                  });

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada jadwal obat untuk 3 hari ke depan.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return Column(
                  children: items
                      .take(6)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HomeMedicationTile(
                            item: item,
                            onTap: () => _showMedicationBottomSheet(
                                context, item, query),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMedicationBottomSheet(
    BuildContext context,
    MedicationCalendarItem item,
    MedicationCalendarRangeQuery query,
  ) async {
    final saved = await showMedicationStatusBottomSheet(
      context: context,
      item: item,
      onSave: (status, currentItem) {
        final scheduledDate = currentItem.scheduledDate;
        if (scheduledDate == null) {
          throw Exception('Tanggal jadwal obat tidak tersedia.');
        }

        return ref.read(profileApiProvider).takeMedication(
              status,
              currentItem.medicationId,
              scheduledDate,
              currentItem.scheduledTime,
            );
      },
      onManage: () {
        context.push('/home/reminder/detail/${item.medicationId}');
      },
      initialStatus: item.status ?? 'Taken',
    );

    if (saved == true) {
      ref.invalidate(medicationCalendarRangeProvider(query));
      try {
        await ref.read(medicationCalendarRangeProvider(query).future);
        if (mounted) {
          AppToast.success(this.context, 'Status obat berhasil diperbarui.');
        }
      } catch (e) {
        if (!mounted) return;
        if (isNetworkRequestError(e)) {
          AppToast.info(
            this.context,
            'Status obat berhasil diperbarui, tetapi daftar terbaru belum bisa dimuat.',
          );
          return;
        }
        rethrow;
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _doseText(num dose) {
    return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  }
}

class _HealthStatusEmptyState extends StatelessWidget {
  const _HealthStatusEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
}

class _HomeMedicationTile extends StatelessWidget {
  const _HomeMedicationTile({
    required this.item,
    required this.onTap,
  });

  final MedicationCalendarItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String dateString = '';
    final date = item.scheduledDate;
    final dateTarget =
        DateTime(date?.year ?? 1970, date?.month ?? 1, date?.day ?? 1);
    final dateRef =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    Duration difference = dateTarget.difference(dateRef);
    int days = difference.inDays;
    switch (days) {
      case 0:
        dateString = 'Hari Ini';
        break;
      case 1:
        dateString = 'Besok';
        break;
      case 2:
        dateString = 'Lusa';
        break;
      case > 3:
        dateString = date!.toIso8601String().substring(0, 10);
        break;
      default:
        dateString = date!.toIso8601String().substring(0, 10);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 42,
              decoration: BoxDecoration(
                color: _resolveColor(item.color),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_doseText(item.singleDose)} ${item.singleDoseUnit} •  $dateString • ${item.scheduledTime}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _StatusChip(status: item.status),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  String _doseText(num dose) {
    return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  }
}

_RiskStyle _riskStyleForScore(double score) {
  if (score < 60) {
    return const _RiskStyle(
      accentColor: Color(0xFF15803D),
      backgroundColor: Color(0xFFF0FDF4),
      borderColor: Color(0xFFBBF7D0),
    );
  }

  if (score < 80) {
    return const _RiskStyle(
      accentColor: Color(0xFFF97316),
      backgroundColor: Color(0xFFFFF7ED),
      borderColor: Color(0xFFFED7AA),
    );
  }

  return const _RiskStyle(
    accentColor: Color(0xFFDC2626),
    backgroundColor: Color(0xFFFEF2F2),
    borderColor: Color(0xFFFECACA),
  );
}

class _RiskStyle {
  const _RiskStyle({
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
}

Color _resolveColor(String raw) {
  final cleaned = raw.replaceFirst('#', '').trim();
  if (cleaned.isEmpty) return const Color(0xFFE64060);

  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0xFFE64060);

  if (cleaned.length <= 6) {
    return Color(0xFF000000 | value);
  }

  return Color(value);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = (status ?? 'open').toLowerCase();
    Color textColor;
    Color bgColor;
    String label;

    switch (value) {
      case 'taken':
        label = medicationStatusUiLabel(value);
        textColor = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'missed':
        label = medicationStatusUiLabel(value);
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'skipped':
        label = medicationStatusUiLabel(value);
        textColor = Colors.orange[800]!;
        bgColor = Colors.orange[200]!;
        break;
      default:
        label = medicationStatusUiLabel(value);
        textColor = Colors.grey[700]!;
        bgColor = Colors.grey[200]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
