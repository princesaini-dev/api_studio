import 'package:equatable/equatable.dart';

class ConnectivityChangeRecord extends Equatable {
  final DateTime timestamp;
  final bool connected;

  const ConnectivityChangeRecord({
    required this.timestamp,
    required this.connected,
  });

  @override
  List<Object?> get props => [timestamp, connected];
}

class ConnectivityPerformance extends Equatable {
  final bool currentConnected;
  final List<ConnectivityChangeRecord> changes;
  final int changeCount;
  final Duration? timeOffline;
  final int? requestsFailedWhileOffline;

  const ConnectivityPerformance({
    this.currentConnected = true,
    this.changes = const [],
    this.changeCount = 0,
    this.timeOffline,
    this.requestsFailedWhileOffline,
  });

  @override
  List<Object?> get props => [
        currentConnected,
        changes,
        changeCount,
        timeOffline,
        requestsFailedWhileOffline
      ];
}
