import 'file_downloader.dart';

/// Pure stub for platforms where neither dart:html nor dart:io is available.
Future<FileDownloadResult> downloadFileBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  return const FileDownloadResult(
    success: false,
    errorMessage: 'File download not supported on this platform.',
  );
}
