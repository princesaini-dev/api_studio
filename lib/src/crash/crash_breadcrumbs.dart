import 'package:flutter/widgets.dart';

import '../domain/entities/api_log_entity.dart';

/// Ring buffer of what happened before a crash: API calls, screen changes
/// and manual notes. Attached to every crash report so the portal can show
/// "the checkout API returned 500, then the app crashed".
///
/// Only already-redacted data is recorded (API calls come from
/// `LogPipeline` after redaction, and never include query strings or
/// bodies).
class CrashBreadcrumbs {
  CrashBreadcrumbs._();

  static const int maxBreadcrumbs = 40;
  static const int _maxMessageLength = 300;

  static final List<Map<String, Object?>> _items = [];

  /// Snapshot, oldest first.
  static List<Map<String, Object?>> get items => List.unmodifiable(_items);

  static void add({
    required String category,
    required String message,
    String? level,
    Map<String, Object?>? data,
    DateTime? timestamp,
  }) {
    try {
      final text = message.length > _maxMessageLength
          ? '${message.substring(0, _maxMessageLength)}…'
          : message;
      _items.add({
        'timestamp': (timestamp ?? DateTime.now()).toUtc().toIso8601String(),
        'category': category,
        'message': text,
        if (level != null) 'level': level,
        if (data != null && data.isNotEmpty) 'data': data,
      });
      if (_items.length > maxBreadcrumbs) {
        _items.removeRange(0, _items.length - maxBreadcrumbs);
      }
    } catch (_) {}
  }

  /// Records a captured (already redacted) API call.
  static void addApiCall(ApiLogEntity log) {
    final uri = Uri.tryParse(log.url);
    final path = uri == null
        ? log.url.split('?').first
        : '${uri.hasAuthority ? '${uri.scheme}://${uri.authority}' : ''}${uri.path}';
    final status = log.statusCode;
    add(
      category: 'http',
      message: '${log.methodLabel} $path ${status ?? 'failed'}',
      level: log.hasError ? 'error' : 'info',
      timestamp: log.timestamp,
      data: {
        'method': log.methodLabel,
        'url': path,
        'status_code': status ?? 0,
        if (log.durationMs != null) 'duration_ms': log.durationMs,
        if (log.errorMessage != null && log.errorMessage!.isNotEmpty)
          'error': log.errorMessage!.length > 200
              ? log.errorMessage!.substring(0, 200)
              : log.errorMessage,
      },
    );
  }

  @visibleForTesting
  static void debugReset() => _items.clear();
}

/// Records screen changes as crash breadcrumbs.
///
/// ```dart
/// MaterialApp(navigatorObservers: [ApiStudioNavigatorObserver()])
/// ```
class ApiStudioNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record('push', route, previousRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record('pop', previousRoute, route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _record('replace', newRoute, oldRoute);

  void _record(String action, Route<dynamic>? to, Route<dynamic>? from) {
    final toName = _name(to);
    if (toName == null) return; // dialogs, sheets and API Studio's own pages
    CrashBreadcrumbs.add(
      category: 'navigation',
      message: '$action → $toName',
      data: {
        'action': action,
        'to': toName,
        if (_name(from) != null) 'from': _name(from),
      },
    );
  }

  static String? _name(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return null;
    return name;
  }
}
