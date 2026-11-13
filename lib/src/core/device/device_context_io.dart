import 'dart:io';

/// Native device context (no plugins required).
Map<String, Object?> describeDevice() {
  try {
    return {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'dart_version': Platform.version.split(' ').first,
    };
  } catch (_) {
    return const {};
  }
}
