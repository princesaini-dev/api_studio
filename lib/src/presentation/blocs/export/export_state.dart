import 'package:equatable/equatable.dart';

enum ExportStatus { idle, exporting, success, failure }

class ExportState extends Equatable {
  final ExportStatus status;
  final String? errorMessage;
  final String? exportedFilePath;

  const ExportState({
    this.status = ExportStatus.idle,
    this.errorMessage,
    this.exportedFilePath,
  });

  ExportState copyWith({
    ExportStatus? status,
    String? errorMessage,
    String? exportedFilePath,
  }) {
    return ExportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, exportedFilePath];
}
