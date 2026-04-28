import 'package:flutter/material.dart';

typedef JsonFetcher = Future<Map<String, dynamic>> Function(Uri uri);

abstract class PatientReportRepository {
  Future<PatientReportResponse> fetchReport({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class BackendPatientReportRepository implements PatientReportRepository {
  BackendPatientReportRepository({
    required this.baseUri,
    required this.getJson,
    this.endpointBuilder,
  });

  final Uri baseUri;
  final JsonFetcher getJson;
  final Uri Function(
    Uri baseUri,
    String patientId,
    DateTime startDate,
    DateTime endDate,
  )? endpointBuilder;

  @override
  Future<PatientReportResponse> fetchReport({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri =
        (endpointBuilder ?? _defaultEndpointBuilder)(
          baseUri,
          patientId,
          startDate,
          endDate,
        );
    final json = await getJson(uri);
    return PatientReportResponse.fromJson(json);
  }

  static Uri _defaultEndpointBuilder(
    Uri baseUri,
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return baseUri.resolve(
      '/api/$patientId/generate-abnormal-report/'
      '?start_date=${_apiDate(startDate)}&end_date=${_apiDate(endDate)}',
    );
  }
}

enum PatientReportPreset { lastTwoWeeks, lastOneMonth }

extension PatientReportPresetX on PatientReportPreset {
  String get label {
    switch (this) {
      case PatientReportPreset.lastTwoWeeks:
        return 'Last 2 Weeks';
      case PatientReportPreset.lastOneMonth:
        return 'Last 1 Month';
    }
  }

  DateTimeRange toRange(DateTime anchor) {
    final end = DateTime(anchor.year, anchor.month, anchor.day);
    switch (this) {
      case PatientReportPreset.lastTwoWeeks:
        return DateTimeRange(
          start: end.subtract(const Duration(days: 14)),
          end: end,
        );
      case PatientReportPreset.lastOneMonth:
        return DateTimeRange(
          start: DateTime(end.year, end.month - 1, end.day),
          end: end,
        );
    }
  }
}

Future<void> showPatientReportFlow(
  BuildContext context, {
  required String patientId,
  required PatientReportRepository repository,
  VoidCallback? onPrintRequested,
  DateTime? now,
}) async {
  final preset = await showModalBottomSheet<PatientReportPreset>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const _PatientReportPresetSheet(),
  );

  if (preset == null || !context.mounted) {
    return;
  }

  final range = preset.toRange(now ?? DateTime.now());

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ReportLoadingDialog(),
  );

  try {
    final response = await repository.fetchReport(
      patientId: patientId,
      startDate: range.start,
      endDate: range.end,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (_) => PatientReportPreviewDialog(
            response: response,
            startDate: range.start,
            endDate: range.end,
            onPrintRequested: onPrintRequested,
          ),
    );
  } catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _ReportErrorDialog(message: error.toString()),
    );
  }
}

class PatientReportPreviewDialog extends StatelessWidget {
  const PatientReportPreviewDialog({
    super.key,
    required this.response,
    required this.startDate,
    required this.endDate,
    this.onPrintRequested,
  });

  final PatientReportResponse response;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onPrintRequested;

  @override
  Widget build(BuildContext context) {
    final report = response.primaryReport;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Document Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ),
                  if (onPrintRequested != null)
                    FilledButton.icon(
                      onPressed: onPrintRequested,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print'),
                    ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child:
                    report == null
                        ? const _EmptyReportState()
                        : PatientReportDocument(
                          report: report,
                          startDate: startDate,
                          endDate: endDate,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientReportDocument extends StatelessWidget {
  const PatientReportDocument({
    super.key,
    required this.report,
    required this.startDate,
    required this.endDate,
  });

  final PatientVitalsReport report;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final rows = report.abnormalRows;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PulseWise',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE13D5A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Medical Vitals Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Period: ${_longDate(startDate)} - ${_longDate(endDate)}',
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CONFIDENTIAL',
                      style: TextStyle(
                        color: Color(0xFFE13D5A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generated: ${_longDate(DateTime.now())}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 2, color: const Color(0xFFE13D5A)),
          const SizedBox(height: 24),
          _ReportBlock(
            title: 'Patient Information',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _InfoTile(label: 'Patient Name', value: report.patientInfo.name),
                _InfoTile(label: 'Patient ID', value: report.patientInfo.id),
                _InfoTile(label: 'Date of Birth', value: report.patientInfo.dob),
                _InfoTile(label: 'Sex', value: report.patientInfo.sex),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ReportBlock(
            title: 'Period Statistics',
            subtitle: '(Avg / Min / Max)',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Blood Pressure',
                  value:
                      '${report.stats.systolicBp.avg}/${report.stats.diastolicBp.avg} mmHg',
                  range:
                      '${report.stats.systolicBp.min}/${report.stats.diastolicBp.min} - '
                      '${report.stats.systolicBp.max}/${report.stats.diastolicBp.max}',
                ),
                _StatCard(
                  title: 'Heart Rate',
                  value: '${report.stats.heartRate.avg} bpm',
                  range:
                      '${report.stats.heartRate.min} - ${report.stats.heartRate.max}',
                ),
                _StatCard(
                  title: 'SpO2',
                  value: '${report.stats.oxygenSaturation.avg} %',
                  range:
                      '${report.stats.oxygenSaturation.min}% - '
                      '${report.stats.oxygenSaturation.max}%',
                ),
                _StatCard(
                  title: 'Weight',
                  value: '${report.stats.weight.avg} kg',
                  range:
                      '${report.stats.weight.min} - ${report.stats.weight.max}',
                ),
                _StatCard(
                  title: 'BMI',
                  value: report.stats.bmi.avg,
                  range:
                      '${report.stats.bmi.min} - ${report.stats.bmi.max}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ReportBlock(
            title: 'Critical Alerts / Abnormalities',
            child:
                rows.isEmpty
                    ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'No abnormal vital signs detected in this reporting period.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columns: const [
                          DataColumn(label: Text('Date & Time')),
                          DataColumn(label: Text('Metric')),
                          DataColumn(label: Text('Value')),
                        ],
                        rows:
                            rows
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(Text(row.date)),
                                      DataCell(
                                        Text(
                                          row.metric,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row.value,
                                          style: const TextStyle(
                                            color: Color(0xFFE13D5A),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                    ),
          ),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'End of Report. Automatically generated by PulseWise System.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientReportResponse {
  const PatientReportResponse({required this.reportData});

  final List<PatientVitalsReport> reportData;

  PatientVitalsReport? get primaryReport =>
      reportData.isEmpty ? null : reportData.first;

  factory PatientReportResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['report_data'] as List<dynamic>? ?? const [];
    return PatientReportResponse(
      reportData:
          rawList
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) => PatientVitalsReport.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
    );
  }
}

class PatientVitalsReport {
  const PatientVitalsReport({
    required this.patientInfo,
    required this.stats,
    required this.abnormalInstances,
  });

  final PatientInfo patientInfo;
  final PatientReportStats stats;
  final List<AbnormalInstance> abnormalInstances;

  List<AbnormalDetailRow> get abnormalRows {
    return [
      for (final instance in abnormalInstances)
        for (final entry in instance.details.entries)
          AbnormalDetailRow(
            date: instance.date,
            metric: entry.key,
            value: entry.value,
          ),
    ];
  }

  factory PatientVitalsReport.fromJson(Map<String, dynamic> json) {
    final rawAbnormal = json['abnormal_instances'] as List<dynamic>? ?? const [];
    return PatientVitalsReport(
      patientInfo: PatientInfo.fromJson(
        Map<String, dynamic>.from(
          json['patient_info'] as Map<dynamic, dynamic>? ?? const {},
        ),
      ),
      stats: PatientReportStats.fromJson(
        Map<String, dynamic>.from(
          json['stats'] as Map<dynamic, dynamic>? ?? const {},
        ),
      ),
      abnormalInstances:
          rawAbnormal
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) => AbnormalInstance.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
    );
  }
}

class PatientInfo {
  const PatientInfo({
    required this.name,
    required this.id,
    required this.dob,
    required this.sex,
  });

  final String name;
  final String id;
  final String dob;
  final String sex;

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      name: '${json['name'] ?? '-'}',
      id: '${json['id'] ?? '-'}',
      dob: '${json['dob'] ?? '-'}',
      sex: '${json['sex'] ?? '-'}',
    );
  }
}

class PatientReportStats {
  const PatientReportStats({
    required this.systolicBp,
    required this.diastolicBp,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.weight,
    required this.bmi,
  });

  final MetricSummary systolicBp;
  final MetricSummary diastolicBp;
  final MetricSummary heartRate;
  final MetricSummary oxygenSaturation;
  final MetricSummary weight;
  final MetricSummary bmi;

  factory PatientReportStats.fromJson(Map<String, dynamic> json) {
    return PatientReportStats(
      systolicBp: MetricSummary.fromJson(json['systolic_bp']),
      diastolicBp: MetricSummary.fromJson(json['diastolic_bp']),
      heartRate: MetricSummary.fromJson(json['heart_rate']),
      oxygenSaturation: MetricSummary.fromJson(json['oxygen_saturation']),
      weight: MetricSummary.fromJson(json['weight']),
      bmi: MetricSummary.fromJson(json['bmi']),
    );
  }
}

class MetricSummary {
  const MetricSummary({
    required this.avg,
    required this.min,
    required this.max,
  });

  final String avg;
  final String min;
  final String max;

  factory MetricSummary.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(
      raw as Map<dynamic, dynamic>? ?? const {},
    );
    return MetricSummary(
      avg: '${json['avg'] ?? '-'}',
      min: '${json['min'] ?? '-'}',
      max: '${json['max'] ?? '-'}',
    );
  }
}

class AbnormalInstance {
  const AbnormalInstance({
    required this.date,
    required this.details,
  });

  final String date;
  final Map<String, String> details;

  factory AbnormalInstance.fromJson(Map<String, dynamic> json) {
    final rawDetails = Map<String, dynamic>.from(
      json['details'] as Map<dynamic, dynamic>? ?? const {},
    );
    return AbnormalInstance(
      date: '${json['date'] ?? '-'}',
      details: rawDetails.map((key, value) => MapEntry(key, '$value')),
    );
  }
}

class AbnormalDetailRow {
  const AbnormalDetailRow({
    required this.date,
    required this.metric,
    required this.value,
  });

  final String date;
  final String metric;
  final String value;
}

class _PatientReportPresetSheet extends StatelessWidget {
  const _PatientReportPresetSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Generate Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Select a timeframe to compile the patient's medical history.",
              style: TextStyle(color: Color(0xFF4A5568)),
            ),
            const SizedBox(height: 20),
            _PresetButton(
              label: 'Last 2 Weeks',
              active: true,
              onTap:
                  () => Navigator.of(
                    context,
                  ).pop(PatientReportPreset.lastTwoWeeks),
            ),
            const SizedBox(height: 12),
            _PresetButton(
              label: 'Last 1 Month',
              onTap:
                  () => Navigator.of(
                    context,
                  ).pop(PatientReportPreset.lastOneMonth),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF0F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFFF99B9F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFFE13D5A) : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }
}

class _ReportLoadingDialog extends StatelessWidget {
  const _ReportLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE13D5A)),
            SizedBox(height: 16),
            Text(
              'Generating medical report...',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportErrorDialog extends StatelessWidget {
  const _ReportErrorDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Failed to generate report'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'No vitals data found for this patient in the selected date range.',
          style: TextStyle(color: Color(0xFF4A5568)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReportBlock extends StatelessWidget {
  const _ReportBlock({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: Color(0xFFE13D5A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                if (subtitle != null)
                  TextSpan(
                    text: ' $subtitle',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.range,
  });

  final String title;
  final String value;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Range: $range',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _apiDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _longDate(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
