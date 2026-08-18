import 'package:equatable/equatable.dart';

class NetworkRequestPerformance extends Equatable {
  final String url;
  final String method;
  final int? statusCode;
  final int? durationMs;
  final DateTime timestamp;
  final bool isSuccess;
  final bool isTimeout;

  const NetworkRequestPerformance({
    required this.url,
    required this.method,
    this.statusCode,
    this.durationMs,
    required this.timestamp,
    this.isSuccess = true,
    this.isTimeout = false,
  });

  @override
  List<Object?> get props =>
      [url, method, statusCode, durationMs, timestamp, isSuccess, isTimeout];
}

class NetworkPerformance extends Equatable {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int timeoutCount;
  final double averageResponseTimeMs;
  final int? slowestRequestMs;
  final int? fastestRequestMs;
  final List<NetworkRequestPerformance> slowRequests;
  final List<NetworkRequestPerformance> recentRequests;

  const NetworkPerformance({
    this.totalRequests = 0,
    this.successfulRequests = 0,
    this.failedRequests = 0,
    this.timeoutCount = 0,
    this.averageResponseTimeMs = 0,
    this.slowestRequestMs,
    this.fastestRequestMs,
    this.slowRequests = const [],
    this.recentRequests = const [],
  });

  bool get hasData => totalRequests > 0;

  @override
  List<Object?> get props => [
        totalRequests,
        successfulRequests,
        failedRequests,
        timeoutCount,
        averageResponseTimeMs,
        slowestRequestMs,
        fastestRequestMs,
        slowRequests,
        recentRequests,
      ];
}
