import 'package:equatable/equatable.dart';

enum FileExplorerEntryType { folder, file }

class FileExplorerEntry extends Equatable {
  final String name;
  final String path;
  final FileExplorerEntryType type;
  final int? sizeBytes;

  const FileExplorerEntry({
    required this.name,
    required this.path,
    required this.type,
    this.sizeBytes,
  });

  bool get isFolder => type == FileExplorerEntryType.folder;
  bool get isFile => type == FileExplorerEntryType.file;

  /// Number of child entries when this is a folder.
  ///
  /// Folders reuse [sizeBytes] to store their child count rather than a
  /// byte size. This getter exposes that value under a clearer name
  /// without changing the underlying field (kept for API compatibility).
  int? get childCount => isFolder ? sizeBytes : null;

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [name, path, type, sizeBytes];
}
