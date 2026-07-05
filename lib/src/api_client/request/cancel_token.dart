import 'dart:async';

/// Token used to cancel an in-flight [ApiStudioClient] request.
///
/// Create one token per request and pass it via the `cancelToken` parameter.
/// Call [cancel] to abort the request.
class CancelToken {
  final _completer = Completer<String>();

  bool _cancelled = false;
  String? _reason;

  /// Whether this token has been cancelled.
  bool get isCancelled => _cancelled;

  /// Cancellation reason, if any.
  String? get reason => _reason;

  /// Internal future resolved when [cancel] is called.
  Future<String> get whenCancel => _completer.future;

  /// Cancels the associated request.
  void cancel([String reason = 'Request cancelled']) {
    if (_cancelled) return;
    _cancelled = true;
    _reason = reason;
    if (!_completer.isCompleted) _completer.complete(reason);
  }
}
