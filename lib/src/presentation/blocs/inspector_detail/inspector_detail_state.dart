import 'package:equatable/equatable.dart';
import '../../../domain/entities/api_log_entity.dart';

enum DetailStatus { initial, loading, success, failure, deleted }

class InspectorDetailState extends Equatable {
  final DetailStatus status;
  final ApiLogEntity? log;
  final int selectedTabIndex;
  final String? errorMessage;
  final bool curlCopied;

  const InspectorDetailState({
    this.status = DetailStatus.initial,
    this.log,
    this.selectedTabIndex = 0,
    this.errorMessage,
    this.curlCopied = false,
  });

  InspectorDetailState copyWith({
    DetailStatus? status,
    ApiLogEntity? log,
    int? selectedTabIndex,
    String? errorMessage,
    bool? curlCopied,
  }) {
    return InspectorDetailState(
      status: status ?? this.status,
      log: log ?? this.log,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      errorMessage: errorMessage ?? this.errorMessage,
      curlCopied: curlCopied ?? this.curlCopied,
    );
  }

  @override
  List<Object?> get props => [status, log, selectedTabIndex, errorMessage, curlCopied];
}
