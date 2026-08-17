import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/list_directory_usecase.dart';
import 'file_explorer_event.dart';
import 'file_explorer_state.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final ListDirectoryUseCase listDirectoryUseCase;

  FileExplorerBloc({
    required this.listDirectoryUseCase,
  }) : super(const FileExplorerState()) {
    on<FileExplorerLoadDirectoryEvent>(_onLoadDirectory);
    on<FileExplorerNavigateToEvent>(_onNavigateTo);
    on<FileExplorerRefreshEvent>(_onRefresh);
  }

  Future<void> _onLoadDirectory(
    FileExplorerLoadDirectoryEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(state.copyWith(
      status: FileExplorerStatus.loading,
      currentPath: event.path,
      errorMessage: null,
    ));
    try {
      final entries = await listDirectoryUseCase(event.path);
      emit(state.copyWith(
        status: entries.isEmpty
            ? FileExplorerStatus.empty
            : FileExplorerStatus.loaded,
        entries: entries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FileExplorerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onNavigateTo(
    FileExplorerNavigateToEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    add(FileExplorerLoadDirectoryEvent(event.path));
  }

  Future<void> _onRefresh(
    FileExplorerRefreshEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    add(FileExplorerLoadDirectoryEvent(state.currentPath));
  }
}
