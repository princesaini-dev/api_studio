import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<String> exportAsJson() async => _writeAndShare(
      ExportFormats.toJson(await _fetchAllLogs()), 'api_studio_logs.json');

  Future<String> exportAsTxt() async => _writeAndShare(
      ExportFormats.toTxt(await _fetchAllLogs()), 'api_studio_logs.txt');

  /// Exports an HTTP Archive (HAR 1.2) file.
  Future<String> exportAsHar() async => _writeAndShare(
      ExportFormats.toHar(await _fetchAllLogs()), 'api_studio_logs.har');

  /// Exports a Postman Collection v2.1 file.
  Future<String> exportAsPostman() async => _writeAndShare(
      ExportFormats.toPostman(await _fetchAllLogs()),
      'api_studio.postman_collection.json');

  Future<String> _writeAndShare(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file.path;
  }
}
