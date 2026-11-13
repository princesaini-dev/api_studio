import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/hive_constants.dart';
import '../../domain/entities/file_explorer_entry.dart';

class FileExplorerDataSource {
  String? _rootPath;

  Future<String> get rootPath async {
    if (_rootPath != null) return _rootPath!;
    final docDir = await getApplicationDocumentsDirectory();
    _rootPath = '${docDir.path}/${HiveConstants.hiveSubDir}';
    return _rootPath!;
  }

  Future<List<FileExplorerEntry>> listDirectory(String path) async {
    final root = await rootPath;
    final dirPath = path.isEmpty ? root : '$root/$path';
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dirPath);
    }

    // Stat files and count folder children concurrently: listing a folder
    // with many subfolders no longer waits on each one in turn.
    final pending = <Future<FileExplorerEntry?>>[];
    await for (final entity in dir.list(followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.isEmpty) continue;

      final relativePath = path.isEmpty ? name : '$path/$name';

      if (entity is Directory) {
        pending.add(entity
            .list(followLinks: false)
            .length
            .then<FileExplorerEntry?>((children) => FileExplorerEntry(
                  name: name,
                  path: relativePath,
                  type: FileExplorerEntryType.folder,
                  sizeBytes: children,
                ))
            .catchError((Object _) => FileExplorerEntry(
                  name: name,
                  path: relativePath,
                  type: FileExplorerEntryType.folder,
                  sizeBytes: 0,
                )));
      } else if (entity is File) {
        pending.add(entity.stat().then<FileExplorerEntry?>(
            (stat) => FileExplorerEntry(
                  name: name,
                  path: relativePath,
                  type: FileExplorerEntryType.file,
                  sizeBytes: stat.size,
                ),
            onError: (Object _) => null));
      }
    }
    final entries = (await Future.wait(pending)).nonNulls.toList();

    entries.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  Future<String> getFilePath(String path) async {
    final root = await rootPath;
    return path.isEmpty ? root : '$root/$path';
  }
}
