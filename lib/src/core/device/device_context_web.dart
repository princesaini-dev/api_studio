import 'package:web/web.dart' as web;

/// Web device context.
Map<String, Object?> describeDevice() {
  try {
    return {
      'os': 'web',
      'user_agent': web.window.navigator.userAgent,
      'locale': web.window.navigator.language,
    };
  } catch (_) {
    return const {};
  }
}
