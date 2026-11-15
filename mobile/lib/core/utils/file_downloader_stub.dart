import 'dart:io';
import 'file_downloader.dart';

/// Non-web (Android, iOS, Desktop) implementation of file download/save.
Future<FileDownloadResult> downloadFileBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final sep = Platform.pathSeparator;
  final candidateDirs = <Directory>[];

  if (Platform.isAndroid) {
    // 1. Primary: Standard public Android Downloads folder
    candidateDirs.add(Directory('/storage/emulated/0/Download'));
    // 2. Secondary: Standard public Download folder
    candidateDirs.add(Directory('/sdcard/Download'));
    // 3. App-specific external files (guaranteed writable without runtime storage permissions on Android 10+)
    candidateDirs.add(
      Directory(
        '/storage/emulated/0/Android/data/com.school.attendify/files/Download',
      ),
    );
  }

  // 4. Guaranteed fallback on all platforms (Android, iOS, Desktop, Test runner)
  candidateDirs.add(Directory.systemTemp);

  for (final dir in candidateDirs) {
    try {
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (_) {
          continue;
        }
      }

      final file = File('${dir.path}$sep$filename');
      await file.writeAsBytes(bytes, flush: true);

      return FileDownloadResult(
        success: true,
        savedPath: file.path,
      );
    } catch (_) {
      // If permission denied or writing failed on this folder, try next candidate
      continue;
    }
  }

  return const FileDownloadResult(
    success: false,
    errorMessage: 'Unable to write file to device storage.',
  );
}
