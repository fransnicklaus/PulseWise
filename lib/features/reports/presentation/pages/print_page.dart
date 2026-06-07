import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrintPage extends ConsumerWidget {
  const PrintPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Ringkasan Metrik'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, 'Laporan Ringkasan Metrik'),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');

    // Fake User Info
    final patientInfo = {
      'Nama': 'John Doe',
      'ID': 'PW-123456',
      'Tanggal Lahir': '1 Januari 1980',
      'Jenis Kelamin': 'Laki-laki',
    };

    // Fake Stats
    final stats = {
      'Blood Pressure': {
        'avg': '118/76',
        'min': '110/70',
        'max': '130/85',
        'unit': 'mmHg'
      },
      'Heart Rate': {'avg': '72', 'min': '65', 'max': '85', 'unit': 'bpm'},
      'SpO2': {'avg': '98', 'min': '96', 'max': '100', 'unit': '%'},
      'Weight': {'avg': '68.2', 'min': '67.5', 'max': '69.0', 'unit': 'kg'},
      'BMI': {'avg': '23.1', 'min': '22.8', 'max': '23.3', 'unit': ''},
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Ringkasan Metrik',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Periode: 14 Hari Terakhir',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red100,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('PRIBADI',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red800)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Dibuat: ${dateFormat.format(now)}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.red800, thickness: 2),
            pw.SizedBox(height: 20),

            // User Information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INFORMASI PENGGUNA',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800)),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: patientInfo.entries.map((entry) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(entry.key.toUpperCase(),
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(entry.value,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Period Summary
            pw.Text('RINGKASAN PERIODE (AVG / MIN / MAX)',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800)),
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stats.entries.map((entry) {
                final s = entry.value;
                return pw.Container(
                  width: (format.availableWidth - 20) / 3, // 3 items per row
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(entry.key,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(s['avg']!,
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 2),
                          pw.Text(s['unit']!,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Range: ${s['min']} - ${s['max']}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 24),

            // Highlighted values
            pw.Text('CATATAN NILAI MENONJOL',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800)),
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'Tidak ada nilai metrik yang menonjol pada periode ini.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800),
              ),
            ),

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                  'Akhir ringkasan. Dokumen ini dibuat otomatis oleh PulseWise.',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }
}
