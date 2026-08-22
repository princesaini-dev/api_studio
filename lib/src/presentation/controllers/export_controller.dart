import 'package:flutter/foundation.dart';

import '../../services/export_service.dart';
import '../states/export_state.dart';

class ExportController extends ChangeNotifier {
  final ExportService exportService;

  ExportState _state = const ExportState();
  ExportState get state => _state;

  ExportController({required this.exportService});

  Future<void> exportAsJson() async {
    _state = _state.copyWith(status: ExportStatus.exporting);
    notifyListeners();
    try {
      final path = await exportService.exportAsJson();
      _state =
          _state.copyWith(status: ExportStatus.success, exportedFilePath: path);
    } catch (e) {
      _state = _state.copyWith(
          status: ExportStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }

  Future<void> exportAsTxt() async {
    _state = _state.copyWith(status: ExportStatus.exporting);
    notifyListeners();
    try {
      final path = await exportService.exportAsTxt();
      _state =
          _state.copyWith(status: ExportStatus.success, exportedFilePath: path);
    } catch (e) {
      _state = _state.copyWith(
          status: ExportStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }
}
