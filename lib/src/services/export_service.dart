import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/redaction/redactor.dart';
import '../core/runtime/api_studio_runtime.dart';
import '../domain/entities/api_log_entity.dart';
import '../domain/repositories/api_log_repository.dart';
import 'export_formats.dart';

/// Writes exports to a temporary file and opens the platform share sheet.
/// All formats apply the active redaction rules (see [ExportFormats]).
class ExportService {
  final ApiLogRepository repository;

  const ExportService({required this.repository});

  Future<List<ApiLogEntity>> _fetchAllLogs() async {
    return repository.getLogs(const GetLogsParams(pageSize: 10000));
  }

  Future<String> exportAsJson() => _export(
      (l, r) => ExportFormats.toJson(l, redactor: r), 'api_studio_logs.json');

  Future<String> exportAsTxt() => _export(
      (l, r) => ExportFormats.toTxt(l, redactor: r), 'api_studio_logs.txt');

  /// Exports an HTTP Archive (HAR 1.2) file.
  Future<String> exportAsHar() => _export(
      (l, r) => ExportFormats.toHar(l, redactor: r), 'api_studio_logs.har');

  /// Exports a Postman Collection v2.1 file.
  Future<String> exportAsPostman() => _export(
      (l, r) => ExportFormats.toPostman(l, redactor: r),
      'api_studio.postman_collection.json');

  /// Redacts and encodes on a background isolate: an export can hold
  /// hundreds of logs with megabytes of bodies, which would otherwise
  /// freeze the UI for seconds. Falls back to the current isolate if the
  /// work can't be sent (e.g. a custom redactor capturing app state).
  Future<String> _export(
    String Function(List<ApiLogEntity> logs, Redactor redactor) encode,
    String fileName,
  ) async {
    final logs = await _fetchAllLogs();
    final redactor = ApiStudioRuntime.redactor;
    String content;
    try {
      content = await compute((_) => encode(logs, redactor), null,
          debugLabel: 'ApiStudio.export');
    } catch (_) {
      content = encode(logs, redactor);
    }
    return _writeAndShare(content, fileName);
  }

  Future<String> _writeAndShare(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file.path;
  }
}
