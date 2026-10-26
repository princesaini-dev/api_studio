import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../redaction/redaction_config.dart';
import '../redaction/redactor.dart';

/// Process-wide runtime configuration shared by the logging pipeline,
/// exporters and UI. Internal.
class ApiStudioRuntime {
  ApiStudioRuntime._();

  /// Master switch. When `false`, every capture/storage/upload path is a
  /// no-op. Set by `ApiStudio.initialize(enabled: ...)`.
  static bool enabled = false;

  /// Maximum size (in UTF-8 bytes) retained for a single request or
  /// response body. Larger bodies are truncated and flagged.
  static int maxBodyBytes = AppConstants.defaultMaxBodyBytes;

  static RedactionConfig _redaction = const RedactionConfig();
  static Redactor _redactor = Redactor(_redaction);

  static RedactionConfig get redaction => _redaction;

  static set redaction(RedactionConfig value) {
    _redaction = value;
    _redactor = Redactor(value);
  }

  static Redactor get redactor => _redactor;

  @visibleForTesting
  static void debugReset() {
    enabled = false;
    maxBodyBytes = AppConstants.defaultMaxBodyBytes;
    redaction = const RedactionConfig();
  }
}
