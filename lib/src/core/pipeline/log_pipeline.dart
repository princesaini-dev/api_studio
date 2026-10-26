import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api_client/core/api_studio_remote_logger.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../notification/services/notification_service.dart';
import '../runtime/api_studio_runtime.dart';

/// The single path every captured request goes through — `ApiStudio.log`,
/// the Dio / http integrations, [ApiStudioClient] and Edit & Run.
///
/// Order of operations: redact → truncate → store locally → notify →
/// queue for remote upload. Redaction always happens first, so unredacted
/// data never reaches storage, notifications or the network. Internal.
class LogPipeline {
  LogPipeline._();

  /// Local repository, wired by `DiService.init`.
  static ApiLogRepository? repository;

  /// Notification service, wired by `DiService.init`.
  static NotificationService? notificationService;

  /// Test hook invoked with every fully-prepared (redacted + truncated) log.
  /// Exposed publicly via `ApiStudio.debugLogListener`.
  static void Function(ApiLogEntity log)? debugListener;

  static const String truncationMarker = '…[truncated by API Studio';

  /// Redacts and truncates [raw] according to [ApiStudioRuntime].
  static ApiLogEntity prepare(ApiLogEntity raw) {
    final redacted = ApiStudioRuntime.redactor.redact(raw);
    final max = ApiStudioRuntime.maxBodyBytes;
    final req = truncate(redacted.requestBody, max);
    final res = truncate(redacted.responseBody, max);
    if (!req.truncated && !res.truncated) return redacted;
    return redacted.copyWith(
      requestBody: req.value,
      responseBody: res.value,
      isTruncated: true,
    );
  }

  /// Truncates [body] to at most [maxBytes] UTF-8 bytes, appending a marker
  /// that states how much was kept.
  static ({String? value, bool truncated}) truncate(
      String? body, int maxBytes) {
    if (body == null || maxBytes <= 0) return (value: body, truncated: false);
    // Fast path: a UTF-16 string never encodes to more than 3 bytes per unit.
    if (body.length * 3 <= maxBytes) return (value: body, truncated: false);
    final bytes = utf8.encode(body);
    if (bytes.length <= maxBytes) return (value: body, truncated: false);
    final kept = utf8.decode(bytes.sublist(0, maxBytes), allowMalformed: true);
    return (
      value:
          '$kept\n$truncationMarker: kept $maxBytes of ${bytes.length} bytes]',
      truncated: true,
    );
  }

  /// Records a captured request. Never throws.
  ///
  /// Returns the stored (redacted) entity, or `null` when API Studio is
  /// disabled or the log could not be prepared.
  static Future<ApiLogEntity?> record(
    ApiLogEntity raw, {
    bool store = true,
    bool upload = true,
    ApiLogRepository? repository,
    NotificationService? notificationService,
  }) async {
    if (!ApiStudioRuntime.enabled) return null;

    final ApiLogEntity entity;
    try {
      entity = prepare(raw);
    } catch (e) {
      // If we cannot redact, we do not record at all.
      debugPrint('[ApiStudio] Dropped a log that could not be redacted: $e');
      return null;
    }

    try {
      debugListener?.call(entity);
    } catch (_) {}

    final repo = repository ?? LogPipeline.repository;
    if (store && repo != null) {
      try {
        await repo.saveLog(entity);
      } catch (_) {}
      final ns = notificationService ?? LogPipeline.notificationService;
      if (entity.hasError && ns != null && ns.hasProviders) {
        unawaited(ns.notifyApiFailed(entity).catchError((_) {}));
      }
    }

    if (upload) ApiStudioRemoteLogger.enqueue(entity);
    return entity;
  }

  @visibleForTesting
  static void debugReset() {
    repository = null;
    notificationService = null;
    debugListener = null;
  }
}
