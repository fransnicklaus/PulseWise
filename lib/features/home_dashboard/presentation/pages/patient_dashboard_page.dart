import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  ConsumerState<PatientDashboardPage> createState() =>
      _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Generate some fake metrics for demonstration
    final sortedMetrics = [
      _FakeMetric(
          heartRate: 72,
          systolic: 118,
          diastolic: 76,
          weight: 68.5,
          height: 172),
      _FakeMetric(
          heartRate: 75,
          systolic: 120,
          diastolic: 80,
          weight: 68.3,
          height: 172),
      _FakeMetric(
          heartRate: 71,
          systolic: 115,
          diastolic: 75,
          weight: 68.1,
          height: 172),
      _FakeMetric(
          heartRate: 74,
          systolic: 119,
          diastolic: 78,
          weight: 68.0,
          height: 172),
      _FakeMetric(
          heartRate: 68,
          systolic: 112,
          diastolic: 72,
          weight: 67.8,
          height: 172),
      _FakeMetric(
          heartRate: 70,
          systolic: 114,
          diastolic: 74,
          weight: 67.5,
          height: 172),
      _FakeMetric(
          heartRate: 73,
          systolic: 118,
          diastolic: 78,
          weight: 67.2,
          height: 172),
    ];

    final latestMetric = sortedMetrics.isNotEmpty ? sortedMetrics.last : null;

    final heartRateSpots = <FlSpot>[];
    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    final weightSpots = <FlSpot>[];

    for (int i = 0; i < sortedMetrics.length; i++) {
      final m = sortedMetrics[i];
      if (m.heartRate != null) {
        heartRateSpots.add(FlSpot(i.toDouble(), m.heartRate!.toDouble()));
      }
      if (m.systolic != null) {
        systolicSpots.add(FlSpot(i.toDouble(), m.systolic!.toDouble()));
      }
      if (m.diastolic != null) {
        diastolicSpots.add(FlSpot(i.toDouble(), m.diastolic!.toDouble()));
      }
      if (m.weight != null) {
        weightSpots.add(FlSpot(i.toDouble(), m.weight!.toDouble()));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F8),
      appBar: CustomAppBar(
        title: 'Dashboard',
        subtitle: 'Lihat riwayat kesehatanmu',
        showBackButton: true,
        onBackPressed: () => context.pop(),
        action: IconButton(
          icon: const Icon(Icons.print, color: Colors.white),
          onPressed: () => context.push('/home/patient-dashboard/print'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientInfoCard(),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Heart Rate',
              icon: Icons.favorite,
              iconColor: const Color(0xFFE13D5A),
              latestValue: '${latestMetric?.heartRate ?? '-'}',
              unit: 'bpm',
              spots: heartRateSpots,
              chartColor: const Color(0xFFE13D5A),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Blood Pressure',
              icon: Icons.monitor_heart,
              iconColor: const Color(0xFFE13D5A),
              latestValue:
                  '${latestMetric?.systolic ?? '-'}/${latestMetric?.diastolic ?? '-'}',
              unit: 'mmHg',
              spots: systolicSpots,
              secondarySpots: diastolicSpots,
              chartColor: Colors.orange,
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Weight',
              icon: Icons.monitor_weight,
              iconColor: const Color(0xFFE13D5A),
              latestValue: '${latestMetric?.weight ?? '-'}',
              unit: 'kg',
              spots: weightSpots,
              chartColor: Colors.blue,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Latest BMI',
                    value: _calculateBmi(
                        latestMetric?.weight, latestMetric?.height),
                    unit: '',
                    bgColor: Colors.white,
                    textColor: const Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Height',
                    value: '${latestMetric?.height ?? '-'}',
                    unit: 'cm',
                    bgColor: const Color(0xFFE13D5A),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateBmi(num? weightKg, num? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return '-';
    double heightM = heightCm / 100;
    double bmi = weightKg / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'PA',
                style: TextStyle(
                  color: Color(0xFFE13D5A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View your health summary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String unit,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String latestValue,
    required String unit,
    required List<FlSpot> spots,
    List<FlSpot>? secondarySpots,
    required Color chartColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Latest Reading',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latestValue,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: spots.isEmpty
                      ? const Center(
                          child: Text('No data available',
                              style: TextStyle(color: Colors.grey)))
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: chartColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: chartColor.withOpacity(0.1),
                                ),
                              ),
                              if (secondarySpots != null)
                                LineChartBarData(
                                  spots: secondarySpots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeMetric {
  final num? heartRate;
  final num? systolic;
  final num? diastolic;
  final num? weight;
  final num? height;

  _FakeMetric({
    this.heartRate,
    this.systolic,
    this.diastolic,
    this.weight,
    this.height,
  });
}
