import 'package:equatable/equatable.dart';

abstract class FileExplorerEvent extends Equatable {
  const FileExplorerEvent();

  @override
  List<Object?> get props => [];
}

class FileExplorerLoadDirectoryEvent extends FileExplorerEvent {
  final String path;
  const FileExplorerLoadDirectoryEvent(this.path);

  @override
  List<Object?> get props => [path];
}

class FileExplorerNavigateToEvent extends FileExplorerEvent {
  final String path;
  const FileExplorerNavigateToEvent(this.path);

  @override
  List<Object?> get props => [path];
}

class FileExplorerRefreshEvent extends FileExplorerEvent {
  const FileExplorerRefreshEvent();
}
