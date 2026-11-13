import 'dart:async';

import '../domain/repositories/api_log_repository.dart';

class FailedApiCountService {
  FailedApiCountService._();

  static final FailedApiCountService _instance = FailedApiCountService._();

  static FailedApiCountService get instance => _instance;

  final StreamController<int> _controller = StreamController<int>.broadcast();

  StreamSubscription<dynamic>? _subscription;
  bool _started = false;
  int _lastCount = 0;
  bool _hasEmitted = false;

  int get failedApiCount => _lastCount;

  Stream<int> get stream => _controller.stream;

  void start(ApiLogRepository repository) {
    if (_started) return;
    _started = true;
    _emitCurrent(repository);
    // watchLogs() only carries the newest page, so use it as a change
    // signal and recount across all stored logs.
    _subscription = repository.watchLogs().listen(
          (_) => unawaited(_emitCurrent(repository)),
        );
  }

  Future<void> _emitCurrent(ApiLogRepository repository) async {
    try {
      final logs = await repository.getLogs(
        const GetLogsParams(
            pageSize: 1 << 30, statusFilter: StatusFilter.error),
      );
      if (logs.length == _lastCount && _hasEmitted) return;
      _hasEmitted = true;
      _lastCount = logs.length;
      if (!_controller.isClosed) _controller.add(_lastCount);
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
    if (!_controller.isClosed) _controller.close();
  }
}
