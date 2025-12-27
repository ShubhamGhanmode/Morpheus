import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExportResult {
  const ExportResult({required this.label, required this.path});

  final String label;
  final String path;
}

class ExportService {
  Future<ExportResult> exportCsv({
    required String fileName,
    required String contents,
  }) async {
    if (Platform.isAndroid) {
      final ok = await _ensureAndroidStoragePermission();
      if (!ok) {
        throw ExportException('Storage permission denied. Please allow access.');
      }
    }

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Download');
      if (!await baseDir.exists()) {
        final candidates = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        baseDir =
            (candidates?.isNotEmpty == true
                    ? candidates!.first
                    : await getExternalStorageDirectory()) ??
                await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory('${baseDir.path}/morpheus_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsString(contents);

    return ExportResult(label: file.path, path: file.path);
  }

  Future<bool> _ensureAndroidStoragePermission() async {
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    return false;
  }
}
