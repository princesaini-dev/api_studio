import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileDownloadService {
  Future<String> download(String sourcePath, String fileName) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    if (Platform.isAndroid) {
      return _downloadAndroid(sourceFile, fileName);
    }

    if (Platform.isIOS) {
      return _downloadViaShare(sourceFile, fileName);
    }

    final destDir = await _getDesktopDownloadDirectory();
    return _copyFile(sourceFile, fileName, destDir);
  }

  Future<String> _downloadAndroid(File sourceFile, String fileName) async {
    const downloadDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];

    for (final path in downloadDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          return _copyFile(sourceFile, fileName, dir);
        } catch (_) {
          continue;
        }
      }
    }

    return _downloadViaShare(sourceFile, fileName);
  }

  Future<Directory> _getDesktopDownloadDirectory() async {
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir;

    try {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    } catch (_) {}

    return getApplicationDocumentsDirectory();
  }

  Future<String> _copyFile(
      File sourceFile, String fileName, Directory destDir) async {
    var finalPath = '${destDir.path}/$fileName';
    var copyIndex = 1;
    while (await File(finalPath).exists()) {
      final dot = fileName.lastIndexOf('.');
      final baseName = dot > 0 ? fileName.substring(0, dot) : fileName;
      final ext = dot > 0 ? fileName.substring(dot) : '';
      finalPath = '${destDir.path}/${baseName}_$copyIndex$ext';
      copyIndex++;
    }

    await sourceFile.copy(finalPath);
    return finalPath;
  }

  Future<String> _downloadViaShare(File sourceFile, String fileName) async {
    await Share.shareXFiles(
      [XFile(sourceFile.path)],
      text: fileName,
    );
    return sourceFile.path;
  }
}
