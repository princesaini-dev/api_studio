import 'dart:async';

import '../domain/entities/api_log_entity.dart';
import '../domain/repositories/api_log_repository.dart';

class FailedApiCountService {
  FailedApiCountService._();

  static final FailedApiCountService _instance = FailedApiCountService._();

  static FailedApiCountService get instance => _instance;

  final StreamController<int> _controller =
      StreamController<int>.broadcast();

  StreamSubscription<List<ApiLogEntity>>? _subscription;
  bool _started = false;
  int _lastCount = 0;

  int get failedApiCount => _lastCount;

  Stream<int> get stream => _controller.stream;

  void start(ApiLogRepository repository) {
    if (_started) return;
    _started = true;
    _emitCurrent(repository);
    _subscription = repository.watchLogs().listen(
      (logs) {
        final failedCount =
            logs.where((log) => log.status == LogStatus.error).length;
        _lastCount = failedCount;
        if (!_controller.isClosed) _controller.add(_lastCount);
      },
    );
  }

  Future<void> _emitCurrent(ApiLogRepository repository) async {
    final logs = await repository.getLogs(
      const GetLogsParams(pageSize: 99999, statusFilter: StatusFilter.error),
    );
    _lastCount = logs.length;
    if (!_controller.isClosed) _controller.add(_lastCount);
  }

  void dispose() {
    _subscription?.cancel();
    if (!_controller.isClosed) _controller.close();
  }
}
