import 'package:equatable/equatable.dart';

import '../../domain/entities/breadcrumb.dart';
import '../../domain/entities/file_explorer_entry.dart';
import '../../core/constants/app_strings.dart';

enum FileExplorerStatus { initial, loading, loaded, empty, error }

class FileExplorerState extends Equatable {
  final FileExplorerStatus status;
  final List<FileExplorerEntry> entries;
  final String currentPath;
  final String? errorMessage;

  const FileExplorerState({
    this.status = FileExplorerStatus.initial,
    this.entries = const [],
    this.currentPath = '',
    this.errorMessage,
  });

  List<Breadcrumb> get breadcrumbs =>
      Breadcrumb.fromPath(currentPath, AppStrings.filesRoot);

  FileExplorerState copyWith({
    FileExplorerStatus? status,
    List<FileExplorerEntry>? entries,
    String? currentPath,
    String? errorMessage,
  }) {
    return FileExplorerState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      currentPath: currentPath ?? this.currentPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        entries,
        currentPath,
        errorMessage,
      ];
}
