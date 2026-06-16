import 'package:equatable/equatable.dart';

abstract class InspectorDetailEvent extends Equatable {
  const InspectorDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadDetailEvent extends InspectorDetailEvent {
  final String logId;
  const LoadDetailEvent(this.logId);

  @override
  List<Object?> get props => [logId];
}

class ChangeDetailTabEvent extends InspectorDetailEvent {
  final int tabIndex;
  const ChangeDetailTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class CopyCurlEvent extends InspectorDetailEvent {
  const CopyCurlEvent();
}

class DeleteDetailLogEvent extends InspectorDetailEvent {
  const DeleteDetailLogEvent();
}
