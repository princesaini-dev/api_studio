import '../entities/file_explorer_entry.dart';

abstract class FileExplorerRepository {
  Future<List<FileExplorerEntry>> listDirectory(String path);
  Future<String> get rootPath;
  Future<String> getFilePath(String path);
}
