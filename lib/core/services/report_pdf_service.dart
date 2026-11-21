import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import '../../features/reports/models/daily_report_model.dart';

/// Generates a PDF document for a daily report.
/// Includes report title, date, site info, and any attached photos.
class ReportPdfService {
  /// Generate PDF bytes for the given [dailyReportModel].
  static Future<Uint8List> generateDailyReportPdf(
    DailyReportModel report, {
    required String? Function(String)? getSiteName,
  }) async {
    final pdf = Document();

    // Build the widget tree for the PDF
    final pdfWidgets = <Widget>[];

    // Add report title if available
    if (report.title != null && report.title!.isNotEmpty) {
      pdfWidgets.add(
        Center(
          child: Text(
            report.title!,
            style: PdfTextStyle(
              fontSize: 24,
              bold: true,
            ),
          ),
        ),
      );
    }

    // Add date
    pdfWidgets.add(
      Center(
        child: Text(
          'Date: ${_formatDate(report.date)}',
          style: PdfTextStyle(fontSize: 14),
        ),
      ),
    );

    // Add site info if getter provided
    if (getSiteName != null) {
      final siteName = getSiteName(report.siteId.toString());
      if (siteName.isNotEmpty) {
        pdfWidgets.add(
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Site: $siteName',
              style: PdfTextStyle(fontSize: 14),
            ),
          ),
        );
      }
    }

    // Add photos if available
    // Note: photo data would need to be fetched from SQLite;
    // this stub includes the structure for photo display.
    pdfWidgets.add(
      const SizedBox(height: 16),
      const Center(child: Text('Photos: (attached images would appear here)')),
    );

    // Add generated timestamp
    pdfWidgets.add(
      const SizedBox(height: 24),
      Center(
        child: Text(
          'Generated: ${DateTime.now().toLocal()}',
          style: PdfTextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ),
    );

    pdf.widgets.addAll(pdfWidgets);

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}