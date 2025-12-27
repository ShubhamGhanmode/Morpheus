import 'dart:html' as html;

class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExportResult {
  const ExportResult({required this.label, this.path});

  final String label;
  final String? path;
}

class ExportService {
  Future<ExportResult> exportCsv({
    required String fileName,
    required String contents,
  }) async {
    final blob = html.Blob([contents], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return const ExportResult(label: 'Download started');
  }
}
