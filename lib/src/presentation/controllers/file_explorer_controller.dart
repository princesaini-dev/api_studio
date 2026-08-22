import 'package:flutter/foundation.dart';

import '../../domain/usecases/list_directory_usecase.dart';
import '../states/file_explorer_state.dart';

class FileExplorerController extends ChangeNotifier {
  final ListDirectoryUseCase listDirectoryUseCase;

  FileExplorerState _state = const FileExplorerState();
  FileExplorerState get state => _state;

  FileExplorerController({required this.listDirectoryUseCase});

  Future<void> loadDirectory(String path) async {
    _state = _state.copyWith(
      status: FileExplorerStatus.loading,
      currentPath: path,
      errorMessage: null,
    );
    notifyListeners();
    try {
      final entries = await listDirectoryUseCase(path);
      _state = _state.copyWith(
        status: entries.isEmpty
            ? FileExplorerStatus.empty
            : FileExplorerStatus.loaded,
        entries: entries,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: FileExplorerStatus.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> navigateTo(String path) async {
    await loadDirectory(path);
  }

  Future<void> refresh() async {
    await loadDirectory(_state.currentPath);
  }
}
