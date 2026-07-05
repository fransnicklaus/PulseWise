import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_flutter.dart'
    as dashboard_ui;

class PrintPage extends StatelessWidget {
  const PrintPage({
    super.key,
    this.dashboardData,
  });

  final dashboard_ui.PatientDashboardData? dashboardData;

  @override
  Widget build(BuildContext context) {
    final data = dashboardData;
    final fileName =
        data == null ? 'pulsewise-dashboard.pdf' : _reportFileName(data);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Export PDF',
        subtitle: 'Dashboard metrik pasien',
        onBackPressed: () => context.pop(),
      ),
      body: data == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 44,
                      color: Color(0xFFE13D5A),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Data dashboard belum tersedia untuk diekspor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buka kembali dashboard pasien lalu tekan tombol print dari halaman metrik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : PdfPreview(
              build: (format) => _generatePdf(format, data),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 720,
              pdfFileName: fileName,
              shouldRepaint: true,
              previewPageMargin: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              padding: const EdgeInsets.all(0),
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: Colors.white,
                iconColor: Color(0xFFE64060),
                elevation: 1,
                height: 64,
                actionSpacing: 14,
                alignment: WrapAlignment.center,
                textStyle: TextStyle(
                  color: Color(0xFFE64060),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              scrollViewDecoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
              ),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              loadingWidget: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE64060),
                ),
              ),
            ),
    );
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat format,
    dashboard_ui.PatientDashboardData data,
  ) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final now = DateTime.now();
    final patient = data.patient;
    final selectedPeriod = data.selectedPeriod?.label ?? 'Dashboard Metrik';
    final logoSvg = await rootBundle.loadString(
      'assets/svgs/pulsewise_logo.svg',
    );

    final heartRateColor =
        _heartRatePdfColor(data.latestHeartRate, data.heartRateThreshold);
    final spo2Color = _spo2PdfColor(data.latestSpo2, data.spo2Threshold);
    final bloodPressureColor = _bloodPressurePdfColor(
      data.latestBloodPressure?.systolic,
      data.latestBloodPressure?.diastolic,
      data.bloodPressureThreshold,
    );
    final weightColor = _weightPdfColor(
      data.latestWeight,
      data.latestWeightPrevious,
      data.weightThreshold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader(
              selectedPeriod: selectedPeriod,
              generatedAt: now,
              logoSvg: logoSvg,
            ),
            pw.SizedBox(height: 12),
            _pdfPatientIdentityCard(patient),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfMiniStatCard(
                    title: 'Latest BMI',
                    value: _formatNumber(data.latestBmi, fractionDigits: 1),
                    suffix: '',
                    background: _pdfWhite,
                    foreground: _pdfInk,
                    borderColor: _pdfStroke,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfMiniStatCard(
                    title: 'Height',
                    value:
                        _formatNumber(data.latestHeightCm, fractionDigits: 0),
                    suffix: 'cm',
                    background: _pdfBrand,
                    foreground: PdfColors.white,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // GRID BARIS 1: Weight & Heart Rate
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfMetricSection(
                    title: 'Weight',
                    accent: weightColor,
                    latestValue:
                        _formatNumber(data.latestWeight, fractionDigits: 1),
                    unit: 'kg',
                    chartSvg: _buildSingleSeriesSvg(
                      data.weightPoints,
                      lineColorHex: '#2563EB',
                      pointColorBuilder: (index, point, previous) {
                        final previousValue = previous?.value;
                        if (previousValue == null) return '#2563EB';
                        final change = (point.value - previousValue).abs();
                        return change >
                                data.weightThreshold.dailyIncreaseCriticalKg
                            ? '#E13D5A'
                            : '#2563EB';
                      },
                    ),
                    summaryLeft: 'Samples: ${data.weightPoints.length}',
                    summaryRight:
                        'Range: ${_rangeText(data.weightPoints, fractionDigits: 1, suffix: ' kg')}',
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfMetricSection(
                    title: 'Heart Rate',
                    accent: heartRateColor,
                    latestValue:
                        _formatNumber(data.latestHeartRate, fractionDigits: 0),
                    unit: 'bpm',
                    chartSvg: _buildSingleSeriesSvg(
                      data.heartRatePoints,
                      lineColorHex: '#2563EB',
                      pointColorBuilder: (index, point, previous) {
                        if (point.value < data.heartRateThreshold.normalMin ||
                            point.value > data.heartRateThreshold.normalMax) {
                          return '#E13D5A';
                        }
                        return '#2563EB';
                      },
                      referenceLines: [
                        data.heartRateThreshold.normalMin,
                        data.heartRateThreshold.normalMax,
                      ],
                    ),
                    summaryLeft: 'Samples: ${data.heartRatePoints.length}',
                    summaryRight:
                        'Normal: ${data.heartRateThreshold.normalMin.toStringAsFixed(0)}-${data.heartRateThreshold.normalMax.toStringAsFixed(0)} bpm',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // GRID BARIS 2: Blood Pressure & Oxygen Saturation
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfMetricSection(
                    title: 'Blood Pressure',
                    accent: bloodPressureColor,
                    latestValue: _formatBloodPressure(data.latestBloodPressure),
                    unit: 'mmHg',
                    chartSvg: _buildBloodPressureSvg(
                      data.bloodPressurePoints,
                      elevatedLine:
                          data.bloodPressureThreshold.elevatedSystolicMin,
                      stage1Line: data.bloodPressureThreshold.stage1SystolicMin,
                      stage2Line: data.bloodPressureThreshold.stage2SystolicMin,
                    ),
                    summaryLeft: 'Samples: ${data.bloodPressurePoints.length}',
                    summaryRight:
                        'Latest: ${_formatBloodPressure(data.latestBloodPressure)} mmHg',
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfMetricSection(
                    title: 'Oxygen Saturation',
                    accent: spo2Color,
                    latestValue:
                        _formatNumber(data.latestSpo2, fractionDigits: 0),
                    unit: '%',
                    chartSvg: _buildSingleSeriesSvg(
                      data.spo2Points,
                      lineColorHex: '#2563EB',
                      pointColorBuilder: (index, point, previous) {
                        if (point.value <
                            data.spo2Threshold.criticalThreshold) {
                          return '#DC2626';
                        }
                        if (point.value < data.spo2Threshold.cautionThreshold) {
                          return '#F59E0B';
                        }
                        return '#2563EB';
                      },
                      referenceLines: [
                        data.spo2Threshold.cautionThreshold,
                        data.spo2Threshold.criticalThreshold,
                      ],
                    ),
                    summaryLeft: 'Samples: ${data.spo2Points.length}',
                    summaryRight:
                        'Threshold: >= ${data.spo2Threshold.cautionThreshold.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Generated from PulseWise Dashboard Metrics',
                style: const pw.TextStyle(color: _pdfSoft, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}

String _reportFileName(dashboard_ui.PatientDashboardData data) {
  final generatedAt = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final period = data.selectedPeriod?.label ?? 'dashboard';
  final safePeriod = period
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final suffix = safePeriod.isEmpty ? 'dashboard' : safePeriod;
  return 'pulsewise-dashboard-$suffix-$generatedAt.pdf';
}

const PdfColor _pdfBrand = PdfColor(225 / 255, 61 / 255, 90 / 255);
const PdfColor _pdfInk = PdfColor(26 / 255, 32 / 255, 44 / 255);
const PdfColor _pdfMuted = PdfColor(74 / 255, 85 / 255, 104 / 255);
const PdfColor _pdfSoft = PdfColor(148 / 255, 163 / 255, 184 / 255);
const PdfColor _pdfPanel = PdfColor(248 / 255, 250 / 255, 252 / 255);
const PdfColor _pdfStroke = PdfColor(241 / 255, 245 / 255, 249 / 255);
const PdfColor _pdfWhite = PdfColors.white;

pw.Widget _pdfHeader({
  required String selectedPeriod,
  required DateTime generatedAt,
  required String logoSvg,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _pdfWhite,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
      border: pw.Border.all(color: _pdfStroke),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _pdfLogoMark(logoSvg),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PulseWise',
                style: pw.TextStyle(
                  color: _pdfBrand,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Dashboard Metrik Pasien',
                style: pw.TextStyle(
                  color: _pdfInk,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _pdfPanel,
                border: pw.Border.all(color: _pdfStroke),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                selectedPeriod,
                style: pw.TextStyle(
                  color: _pdfBrand,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              DateFormat('d MMM yyyy, HH:mm').format(generatedAt),
              style: const pw.TextStyle(color: _pdfSoft, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pdfLogoMark(String logoSvg) {
  return pw.SizedBox(
    width: 50,
    height: 50,
    child: pw.SvgImage(
      svg: logoSvg,
      fit: pw.BoxFit.contain,
    ),
  );
}

pw.Widget _pdfPatientIdentityCard(dashboard_ui.PatientProfile patient) {
  final entries = [
    ('Nama Pasien', patient.fullName.isEmpty ? '-' : patient.fullName),
    ('Patient ID', patient.id),
    ('Tanggal Lahir', _formatDateLabel(patient.dateOfBirth)),
    ('Jenis Kelamin', _formatSex(patient.sex)),
    ('Email', _normalizeText(patient.email)),
  ];

  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: _pdfPanel,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
      border: pw.Border.all(color: _pdfStroke),
    ),
    child: pw.Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final entry in entries)
          pw.SizedBox(
            width: 170,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  entry.$1.toUpperCase(),
                  style: pw.TextStyle(
                    color: _pdfSoft,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  entry.$2,
                  style: pw.TextStyle(
                    color: _pdfInk,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _pdfMiniStatCard({
  required String title,
  required String value,
  required String suffix,
  required PdfColor background,
  required PdfColor foreground,
  PdfColor? borderColor,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: background,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
      border: borderColor == null ? null : pw.Border.all(color: borderColor),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (suffix.isNotEmpty) ...[
              pw.SizedBox(width: 2),
              pw.Text(
                suffix,
                style: pw.TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pdfMetricSection({
  required String title,
  required PdfColor accent,
  required String latestValue,
  required String unit,
  required String chartSvg,
  required String summaryLeft,
  required String summaryRight,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: _pdfWhite,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
      border: pw.Border.all(color: _pdfStroke),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: _pdfInk,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Text(
              '$latestValue $unit',
              style: pw.TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 75,
          padding: const pw.EdgeInsets.all(4),
          decoration: const pw.BoxDecoration(
            color: _pdfPanel,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.SvgImage(svg: chartSvg),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              summaryLeft,
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 8.5),
            ),
            pw.Text(
              summaryRight,
              style: const pw.TextStyle(color: _pdfMuted, fontSize: 8.5),
            ),
          ],
        ),
      ],
    ),
  );
}

String _buildSingleSeriesSvg(
  List<dashboard_ui.ChartPoint> points, {
  required String lineColorHex,
  required String Function(
    int index,
    dashboard_ui.ChartPoint current,
    dashboard_ui.ChartPoint? previous,
  ) pointColorBuilder,
  List<double> referenceLines = const [],
}) {
  if (points.isEmpty) {
    return _buildEmptyChartSvg('Tidak ada data metrik');
  }

  const width = 520.0;
  const height = 140.0;
  const left = 24.0;
  const top = 12.0;
  const right = 10.0;
  const bottom = 28.0;
  const plotWidth = width - left - right;
  const plotHeight = height - top - bottom;

  final values = points.map((point) => point.value).toList();
  var minValue = values.reduce(math.min);
  var maxValue = values.reduce(math.max);
  if ((maxValue - minValue).abs() < 0.01) {
    maxValue += 1;
    minValue -= 1;
  }
  final padding = math.max((maxValue - minValue) * 0.15, 1.5);
  minValue -= padding;
  maxValue += padding;

  double mapX(int index) {
    if (points.length == 1) return left + plotWidth / 2;
    return left + (plotWidth * index / (points.length - 1));
  }

  double mapY(double value) {
    final ratio = (value - minValue) / (maxValue - minValue);
    return top + plotHeight - (ratio * plotHeight);
  }

  final polyline = [
    for (var i = 0; i < points.length; i++)
      '${mapX(i).toStringAsFixed(2)},${mapY(points[i].value).toStringAsFixed(2)}',
  ].join(' ');

  final circles = <String>[];
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final previous = i == 0 ? null : points[i - 1];
    final fill = pointColorBuilder(i, current, previous);
    circles.add(
      '<circle cx="${mapX(i).toStringAsFixed(2)}" cy="${mapY(current.value).toStringAsFixed(2)}" r="3.6" fill="$fill" stroke="#FFFFFF" stroke-width="1.4" />',
    );
  }

  final gridLines = List.generate(4, (index) {
    final y = top + (plotHeight * index / 3);
    return '<line x1="$left" y1="${y.toStringAsFixed(2)}" x2="${(left + plotWidth).toStringAsFixed(2)}" y2="${y.toStringAsFixed(2)}" stroke="#E2E8F0" stroke-width="1" />';
  }).join();

  final refs = referenceLines.map((value) {
    final y = mapY(value).clamp(top, top + plotHeight);
    return '<line x1="$left" y1="${y.toStringAsFixed(2)}" x2="${(left + plotWidth).toStringAsFixed(2)}" y2="${y.toStringAsFixed(2)}" stroke="#CBD5E1" stroke-width="1" stroke-dasharray="5 5" />';
  }).join();

  final xLabels = _buildDateLabelsSvg(
    points.map((point) => point.timestamp).toList(),
    left: left,
    plotWidth: plotWidth,
    y: height - 8,
  );

  return '''<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="$width" height="$height" rx="18" fill="#FFFFFF" />
  $gridLines
  $refs
  <polyline points="$polyline" fill="none" stroke="$lineColorHex" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
  ${circles.join()}
  $xLabels
</svg>''';
}

String _buildBloodPressureSvg(
  List<dashboard_ui.BloodPressurePoint> points, {
  required double elevatedLine,
  required double stage1Line,
  required double stage2Line,
}) {
  if (points.isEmpty) {
    return _buildEmptyChartSvg('Belum ada data tekanan darah');
  }

  const width = 520.0;
  const height = 140.0;
  const left = 24.0;
  const top = 12.0;
  const right = 10.0;
  const bottom = 28.0;
  const plotWidth = width - left - right;
  const plotHeight = height - top - bottom;

  final allValues = [
    for (final point in points) point.systolic,
    for (final point in points) point.diastolic,
  ];
  var minValue = allValues.reduce(math.min);
  var maxValue = allValues.reduce(math.max);
  if ((maxValue - minValue).abs() < 0.01) {
    maxValue += 1;
    minValue -= 1;
  }
  final padding = math.max((maxValue - minValue) * 0.15, 4.0);
  minValue -= padding;
  maxValue += padding;

  double mapX(int index) {
    if (points.length == 1) return left + plotWidth / 2;
    return left + (plotWidth * index / (points.length - 1));
  }

  double mapY(double value) {
    final ratio = (value - minValue) / (maxValue - minValue);
    return top + plotHeight - (ratio * plotHeight);
  }

  final systolic = [
    for (var i = 0; i < points.length; i++)
      '${mapX(i).toStringAsFixed(2)},${mapY(points[i].systolic).toStringAsFixed(2)}',
  ].join(' ');
  final diastolic = [
    for (var i = 0; i < points.length; i++)
      '${mapX(i).toStringAsFixed(2)},${mapY(points[i].diastolic).toStringAsFixed(2)}',
  ].join(' ');

  final circles = <String>[];
  for (var i = 0; i < points.length; i++) {
    circles.add(
      '<circle cx="${mapX(i).toStringAsFixed(2)}" cy="${mapY(points[i].systolic).toStringAsFixed(2)}" r="3.4" fill="#E13D5A" stroke="#FFFFFF" stroke-width="1.4" />',
    );
    circles.add(
      '<circle cx="${mapX(i).toStringAsFixed(2)}" cy="${mapY(points[i].diastolic).toStringAsFixed(2)}" r="3.4" fill="#2563EB" stroke="#FFFFFF" stroke-width="1.4" />',
    );
  }

  final gridLines = List.generate(4, (index) {
    final y = top + (plotHeight * index / 3);
    return '<line x1="$left" y1="${y.toStringAsFixed(2)}" x2="${(left + plotWidth).toStringAsFixed(2)}" y2="${y.toStringAsFixed(2)}" stroke="#E2E8F0" stroke-width="1" />';
  }).join();

  final refs = [elevatedLine, stage1Line, stage2Line].map((value) {
    final y = mapY(value).clamp(top, top + plotHeight);
    return '<line x1="$left" y1="${y.toStringAsFixed(2)}" x2="${(left + plotWidth).toStringAsFixed(2)}" y2="${y.toStringAsFixed(2)}" stroke="#CBD5E1" stroke-width="1" stroke-dasharray="5 5" />';
  }).join();

  final xLabels = _buildDateLabelsSvg(
    points.map((point) => point.timestamp).toList(),
    left: left,
    plotWidth: plotWidth,
    y: height - 8,
  );

  return '''<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="$width" height="$height" rx="18" fill="#FFFFFF" />
  $gridLines
  $refs
  <polyline points="$systolic" fill="none" stroke="#E13D5A" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
  <polyline points="$diastolic" fill="none" stroke="#2563EB" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
  ${circles.join()}
  $xLabels
</svg>''';
}

String _buildDateLabelsSvg(
  List<DateTime> timestamps, {
  required double left,
  required double plotWidth,
  required double y,
}) {
  if (timestamps.isEmpty) return '';

  final indices = <int>{0, timestamps.length - 1};
  if (timestamps.length > 2) {
    indices.add((timestamps.length - 1) ~/ 2);
  }
  if (timestamps.length > 4) {
    indices.add(((timestamps.length - 1) * 0.25).round());
    indices.add(((timestamps.length - 1) * 0.75).round());
  }

  final sorted = indices.toList()..sort();
  final labels = <String>[];

  for (final index in sorted) {
    final x = timestamps.length == 1
        ? left + plotWidth / 2
        : left + (plotWidth * index / (timestamps.length - 1));
    final label =
        '${timestamps[index].day} ${_monthShort(timestamps[index].month)}';
    labels.add(
      '<text x="${x.toStringAsFixed(2)}" y="${y.toStringAsFixed(2)}" text-anchor="middle" font-size="10" fill="#94A3B8" font-family="Arial">$label</text>',
    );
  }

  return labels.join();
}

String _buildEmptyChartSvg(String label) {
  return '''<svg viewBox="0 0 520 140" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="520" height="140" rx="18" fill="#F8FAFC" />
  <text x="260" y="74" text-anchor="middle" font-size="13" fill="#94A3B8" font-family="Arial">$label</text>
</svg>''';
}

String _monthShort(int month) {
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
    'Dec',
  ];
  return months[month - 1];
}

String _formatNumber(num? value, {int fractionDigits = 1}) {
  if (value == null) return '-';
  return value.toStringAsFixed(fractionDigits);
}

String _rangeText(
  List<dashboard_ui.ChartPoint> points, {
  required int fractionDigits,
  required String suffix,
}) {
  if (points.isEmpty) return '-';
  final values = points.map((point) => point.value).toList();
  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  return '${minValue.toStringAsFixed(fractionDigits)} - ${maxValue.toStringAsFixed(fractionDigits)}$suffix';
}

String _formatBloodPressure(dashboard_ui.BloodPressurePoint? point) {
  if (point == null) return '-';
  return '${point.systolic.toStringAsFixed(0)}/${point.diastolic.toStringAsFixed(0)}';
}

String _normalizeText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '-' : trimmed;
}

String _formatDateLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('d MMM yyyy').format(parsed);
}

String _formatSex(String? raw) {
  final value = raw?.trim().toLowerCase() ?? '';
  if (value.isEmpty) return '-';
  if (value == 'male') return 'Male';
  if (value == 'female') return 'Female';
  return raw!;
}

PdfColor _heartRatePdfColor(
    double? value, dashboard_ui.HeartRateThreshold threshold) {
  if (value == null) return _pdfInk;
  if (value < threshold.normalMin || value > threshold.normalMax) {
    return _pdfBrand;
  }
  return const PdfColor(37 / 255, 99 / 255, 235 / 255);
}

PdfColor _spo2PdfColor(double? value, dashboard_ui.Spo2Threshold threshold) {
  if (value == null) return _pdfInk;
  if (value < threshold.criticalThreshold) {
    return const PdfColor(220 / 255, 38 / 255, 38 / 255);
  }
  if (value < threshold.cautionThreshold) {
    return const PdfColor(245 / 255, 158 / 255, 11 / 255);
  }
  return const PdfColor(37 / 255, 99 / 255, 235 / 255);
}

PdfColor _bloodPressurePdfColor(double? systolic, double? diastolic,
    dashboard_ui.BloodPressureThreshold threshold) {
  if (systolic == null || diastolic == null) return _pdfInk;
  if (systolic >= threshold.stage2SystolicMin ||
      diastolic >= threshold.stage2DiastolicMin) {
    return const PdfColor(220 / 255, 38 / 255, 38 / 255);
  }
  if ((systolic >= threshold.stage1SystolicMin &&
          systolic <= threshold.stage1SystolicMax) ||
      (diastolic >= threshold.stage1DiastolicMin &&
          diastolic <= threshold.stage1DiastolicMax)) {
    return const PdfColor(249 / 255, 115 / 255, 22 / 255);
  }
  if (systolic >= threshold.elevatedSystolicMin &&
      systolic <= threshold.elevatedSystolicMax &&
      diastolic < threshold.elevatedDiastolicMax) {
    return const PdfColor(245 / 255, 158 / 255, 11 / 255);
  }
  return const PdfColor(37 / 255, 99 / 255, 235 / 255);
}

PdfColor _weightPdfColor(
    double? current, double? previous, dashboard_ui.WeightThreshold threshold) {
  if (current == null) return _pdfInk;
  if (previous == null) return const PdfColor(37 / 255, 99 / 255, 235 / 255);
  final change = (current - previous).abs();
  if (change > threshold.dailyIncreaseCriticalKg) {
    return _pdfBrand;
  }
  return const PdfColor(37 / 255, 99 / 255, 235 / 255);
}
