import 'dart:async';

import 'connectivity_checker_native.dart'
    if (dart.library.html) 'connectivity_checker_web.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();

  static ConnectivityService get instance => _instance;

  static const Duration _pollInterval = Duration(seconds: 5);

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  Timer? _timer;
  bool _isConnected = false;
  bool _started = false;

  /// Last known connectivity state. Synchronous — no await needed.
  bool get isConnected => _isConnected;

  /// Broadcast stream emitting [true]/[false] on each connectivity change.
  Stream<bool> get stream => _controller.stream;

  /// Starts periodic polling. Safe to call multiple times — only initialises once.
  void start() {
    if (_started) return;
    _started = true;
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  /// Stops polling and closes the stream. Call on app dispose if needed.
  void dispose() {
    _timer?.cancel();
    if (!_controller.isClosed) _controller.close();
  }

  Future<void> _poll() async {
    final result = await _checkConnectivity();
    if (result != _isConnected) {
      _isConnected = result;
      if (!_controller.isClosed) _controller.add(_isConnected);
    }
  }

  Future<bool> _checkConnectivity() => checkConnectivity();
}
