import '../../domain/entities/file_explorer_entry.dart';

class FileExplorerDataSource {
  Future<List<FileExplorerEntry>> listDirectory(String path) async {
    throw UnsupportedError('File Explorer is not available on this platform');
  }

  Future<String> getFilePath(String path) async {
    throw UnsupportedError('File Explorer is not available on this platform');
  }

  Future<String> get rootPath async => '';
}
