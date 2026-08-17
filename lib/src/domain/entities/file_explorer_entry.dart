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

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [name, path, type, sizeBytes];
}
