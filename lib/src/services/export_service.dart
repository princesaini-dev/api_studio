import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/entities/api_log_entity.dart';
import '../domain/repositories/api_log_repository.dart';

class ExportService {
  final ApiLogRepository repository;

  const ExportService({required this.repository});

  Future<List<ApiLogEntity>> _fetchAllLogs() async {
    return repository.getLogs(const GetLogsParams(pageSize: 10000));
  }

  Future<String> exportAsJson() async {
    final logs = await _fetchAllLogs();
    final jsonList = logs.map(_logToMap).toList();
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(jsonList);
    return _writeAndShare(content, 'api_inspector_logs.json');
  }

  Future<String> exportAsTxt() async {
    final logs = await _fetchAllLogs();
    final buffer = StringBuffer();
    buffer.writeln('FA API Inspector — Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total: ${logs.length} requests\n');
    buffer.writeln('=' * 60);
    for (final log in logs) {
      buffer.writeln('\n[${log.timestamp}] ${log.methodLabel} ${log.url}');
      buffer.writeln(
          'Status: ${log.statusCode ?? 'N/A'} | Duration: ${log.durationMs ?? '?'}ms');
      if (log.requestBody != null) buffer.writeln('Body: ${log.requestBody}');
      if (log.errorMessage != null) {
        buffer.writeln('Error: ${log.errorMessage}');
      }
      buffer.writeln('-' * 60);
    }
    return _writeAndShare(buffer.toString(), 'api_inspector_logs.txt');
  }

  Map<String, dynamic> _logToMap(ApiLogEntity log) => {
        'id': log.id,
        'url': log.url,
        'method': log.methodLabel,
        'timestamp': log.timestamp.toIso8601String(),
        'durationMs': log.durationMs,
        'statusCode': log.statusCode,
        'status': log.status.name,
        'requestHeaders': log.requestHeaders,
        'queryParams': log.queryParams,
        'requestBody': log.requestBody,
        'responseHeaders': log.responseHeaders,
        'responseBody': log.responseBody,
        'errorMessage': log.errorMessage,
        'isEdited': log.isEdited,
        'parentId': log.parentId,
      };

  Future<String> _writeAndShare(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)]);
    return file.path;
  }
}
