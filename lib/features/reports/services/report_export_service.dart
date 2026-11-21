/// Integration service for PDF export operations.
/// Mediates between DailyReportProvider and ReportPdfService,
/// handling local notifications and state changes after export.
class ReportExportService {
  /// Export a daily report to PDF and optionally show local notification.
  static Future<Uint8List> exportReportPdf(
    DailyReportModel report, {
    required String? Function(String) getSiteName,
    required DynamikReportProvider provider,
  }) async {
    final pdfBytes = await ReportPdfService.generateDailyReportPdf(
      report,
      getSiteName: getSiteName,
    );

    // TODO: Add local notification via flutter_local_notifications
    // when PDF export completes successfully.

    return pdfBytes;
  }
}