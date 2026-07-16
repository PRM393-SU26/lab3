import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/analytics.dart';
import '../models/author_detail.dart';

class DashboardExportService {
  /// Upload a generated PDF report to Firebase Storage and return download URL.
  static Future<String> uploadReportToFirebase(Uint8List pdfBytes, String topic) async {
    final storageRef = FirebaseStorage.instance.ref();
    final cleanTopic = topic.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final reportRef = storageRef.child('reports/report_${cleanTopic}_$timestamp.pdf');

    final uploadTask = reportRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    // Timeout after 15 seconds to prevent infinite spinner if Storage isn't setup
    final snapshot = await uploadTask.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Upload timed out. Please check if Firebase Storage is enabled in the console and has correct rules.'),
    );
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  static Future<Uint8List> generatePdf(
    TopicDashboard db,
    List<OaStat> oaBreakdown,
  ) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final ttf = await PdfGoogleFonts.robotoRegular().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Failed to download PDF font.'),
    );
    final ttfBold = await PdfGoogleFonts.robotoBold().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Failed to download PDF bold font.'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                db.topic,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Research Insights Report',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 4),
              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 16),

              pw.Text(
                'Overview Statistics',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _tableCell('Total Publications', '${db.totalPublications}'),
                      _tableCell(
                        'Avg Citations',
                        db.avgCitationCount.toStringAsFixed(1),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell(
                        'Open Access',
                        '${(db.openAccessRatio * 100).toStringAsFixed(1)}%',
                      ),
                      _tableCell(
                        'Peak Year',
                        db.peakYear != null ? '${db.peakYear}' : 'N/A',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Key Contributors',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Top Journal: ${db.topJournalName ?? 'N/A'}'),
              pw.SizedBox(height: 4),
              pw.Text('Top Author: ${db.topAuthorName ?? 'N/A'}'),

              if (db.mostInfluentialTitle != null) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Most Influential Paper',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(db.mostInfluentialTitle!),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Citations: ${db.mostInfluentialCitations ?? 0}',
                ),
              ],

              if (oaBreakdown.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Open Access Breakdown',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                for (final stat in oaBreakdown)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '${stat.status.toUpperCase()}: ${stat.count}',
                    ),
                  ),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated by Journal Trend Analyzer',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _tableCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Upload an arbitrary PDF file bytes to Firebase Storage under uploads/ directory.
  static Future<String> uploadCustomPdfToFirebase(Uint8List pdfBytes, String fileName) async {
    final storageRef = FirebaseStorage.instance.ref();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Sanitize file name
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '_');
    final uploadRef = storageRef.child('uploads/pdf_${timestamp}_$cleanName');

    final uploadTask = uploadRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    final snapshot = await uploadTask.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw Exception('Upload timed out. Please check your internet and Firebase Storage rules.'),
    );
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String topic) async {
    final xFile = XFile.fromData(
      pdfBytes,
      mimeType: 'application/pdf',
      name: 'report_$topic.pdf',
    );
    await Share.shareXFiles(
      [xFile],
      text: 'Research Insights: $topic',
    );
  }
}
