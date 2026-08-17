import 'dart:io';

import '../../core/errors/failures.dart';
import '../../domain/entities/file_explorer_entry.dart';
import '../../domain/repositories/file_explorer_repository.dart';
import '../datasources/file_explorer_datasource.dart'
    if (dart.library.io) '../datasources/file_explorer_datasource_io.dart'
    if (dart.library.html) '../datasources/file_explorer_datasource_web.dart';

class FileExplorerRepositoryImpl implements FileExplorerRepository {
  final FileExplorerDataSource _dataSource;

  FileExplorerRepositoryImpl(this._dataSource);

  @override
  Future<List<FileExplorerEntry>> listDirectory(String path) async {
    try {
      return await _dataSource.listDirectory(path);
    } on FileSystemException catch (e) {
      throw StorageFailure(
          e.message.isNotEmpty ? e.message : 'Failed to list directory');
    } on UnsupportedError catch (e) {
      throw StorageFailure(e.message ?? 'Operation not supported');
    } catch (e) {
      throw StorageFailure('Failed to list directory: $e');
    }
  }

  @override
  Future<String> get rootPath => _dataSource.rootPath;

  @override
  Future<String> getFilePath(String path) async {
    try {
      return await _dataSource.getFilePath(path);
    } catch (e) {
      throw StorageFailure('Failed to resolve file path: $e');
    }
  }
}
