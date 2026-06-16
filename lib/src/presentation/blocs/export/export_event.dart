import 'package:equatable/equatable.dart';

abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class ExportAsJsonEvent extends ExportEvent {
  const ExportAsJsonEvent();
}

class ExportAsTxtEvent extends ExportEvent {
  const ExportAsTxtEvent();
}
