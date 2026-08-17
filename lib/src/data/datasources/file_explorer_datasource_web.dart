import '../../domain/entities/file_explorer_entry.dart';

class FileExplorerDataSource {
  Future<String> get rootPath async => '';

  Future<List<FileExplorerEntry>> listDirectory(String path) async {
    throw UnsupportedError('File Explorer is not available on web');
  }

  Future<String> getFilePath(String path) async {
    throw UnsupportedError('File Explorer is not available on web');
  }
}
