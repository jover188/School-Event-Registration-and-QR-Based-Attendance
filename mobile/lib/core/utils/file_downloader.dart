import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    as platform;

/// Result envelope for cross-platform file download operations.
class FileDownloadResult {
  final bool success;
  final String? savedPath;
  final String? errorMessage;

  const FileDownloadResult({
    required this.success,
    this.savedPath,
    this.errorMessage,
  });
}

/// Downloads or saves raw byte data to the appropriate location depending on the platform.
///
/// On Web: Triggers an in-browser file download using a temporary Blob URL and anchor element.
/// On Mobile/Desktop: Saves the file directly to the device filesystem.
Future<FileDownloadResult> downloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) =>
    platform.downloadFileBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
