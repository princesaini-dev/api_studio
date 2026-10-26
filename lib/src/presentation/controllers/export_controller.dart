import 'package:flutter/foundation.dart';

import '../../services/export_service.dart';
import '../states/export_state.dart';

class ExportController extends ChangeNotifier {
  final ExportService exportService;

  ExportState _state = const ExportState();
  ExportState get state => _state;

  ExportController({required this.exportService});

  Future<void> exportAsJson() => _run(exportService.exportAsJson);

  Future<void> exportAsTxt() => _run(exportService.exportAsTxt);

  /// Exports all logs as an HTTP Archive (HAR 1.2) file.
  Future<void> exportAsHar() => _run(exportService.exportAsHar);

  /// Exports all logs as a Postman Collection v2.1.
  Future<void> exportAsPostman() => _run(exportService.exportAsPostman);

  Future<void> _run(Future<String> Function() export) async {
    _state = _state.copyWith(status: ExportStatus.exporting);
    notifyListeners();
    try {
      final path = await export();
      _state =
          _state.copyWith(status: ExportStatus.success, exportedFilePath: path);
    } catch (e) {
      _state = _state.copyWith(
          status: ExportStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }
}
