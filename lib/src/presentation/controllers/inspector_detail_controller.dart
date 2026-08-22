import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/repositories/api_log_repository.dart';
import '../../domain/usecases/delete_log_usecase.dart';
import '../../core/utils/curl_generator.dart';
import '../states/inspector_detail_state.dart';

class InspectorDetailController extends ChangeNotifier {
  final ApiLogRepository repository;
  final DeleteLogUseCase deleteLogUseCase;

  InspectorDetailState _state = const InspectorDetailState();
  InspectorDetailState get state => _state;

  InspectorDetailController({
    required this.repository,
    required this.deleteLogUseCase,
  });

  Future<void> loadDetail(String logId) async {
    _state = _state.copyWith(status: DetailStatus.loading);
    notifyListeners();
    try {
      final log = await repository.getLogById(logId);
      if (log == null) {
        _state = _state.copyWith(
            status: DetailStatus.failure, errorMessage: 'Log not found');
        notifyListeners();
        return;
      }
      _state = _state.copyWith(status: DetailStatus.success, log: log);
    } catch (e) {
      _state = _state.copyWith(
          status: DetailStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }

  void changeTab(int tabIndex) {
    _state = _state.copyWith(selectedTabIndex: tabIndex);
    notifyListeners();
  }

  Future<void> copyCurl() async {
    if (_state.log == null) return;
    final curl = CurlGenerator.generate(_state.log!);
    await Clipboard.setData(ClipboardData(text: curl));
    _state = _state.copyWith(curlCopied: true);
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 2));
    _state = _state.copyWith(curlCopied: false);
    notifyListeners();
  }

  Future<void> deleteLog() async {
    if (_state.log == null) return;
    await deleteLogUseCase(_state.log!.id);
    _state = _state.copyWith(status: DetailStatus.deleted);
    notifyListeners();
  }
}
