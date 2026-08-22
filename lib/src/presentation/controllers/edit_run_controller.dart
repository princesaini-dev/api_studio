import 'package:flutter/foundation.dart';

import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../domain/usecases/run_request_usecase.dart';
import '../states/edit_run_state.dart';

class EditRunController extends ChangeNotifier {
  final RunRequestUseCase runRequestUseCase;
  final _uuid = const UuidGenerator();

  EditRunState _state = const EditRunState();
  EditRunState get state => _state;

  EditRunController({required this.runRequestUseCase});

  void init(ApiLogEntity log) {
    _state = EditRunState(
      originalLog: log,
      url: log.url,
      method: log.method,
      headers: Map<String, dynamic>.from(log.requestHeaders),
      queryParams: Map<String, dynamic>.from(log.queryParams),
      body: log.requestBody,
    );
    notifyListeners();
  }

  void updateUrl(String url) {
    _state = _state.copyWith(url: url);
    notifyListeners();
  }

  void updateMethod(HttpMethod method) {
    _state = _state.copyWith(method: method);
    notifyListeners();
  }

  void updateHeaders(Map<String, dynamic> headers) {
    _state = _state.copyWith(headers: headers);
    notifyListeners();
  }

  void updateQueryParams(Map<String, dynamic> params) {
    _state = _state.copyWith(queryParams: params);
    notifyListeners();
  }

  void updateBody(String? body) {
    _state = _state.copyWith(body: body);
    notifyListeners();
  }

  Future<void> runRequest() async {
    if (_state.originalLog == null) return;
    _state = _state.copyWith(status: EditRunStatus.running);
    notifyListeners();
    try {
      final result = await runRequestUseCase(RunRequestParams(
        originalLog: _state.originalLog!,
        url: _state.url,
        method: _state.method,
        headers: _state.headers,
        queryParams: _state.queryParams,
        body: _state.body,
        newId: _uuid.v4(),
      ));
      _state =
          _state.copyWith(status: EditRunStatus.success, resultLog: result);
    } catch (e) {
      _state = _state.copyWith(
          status: EditRunStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }
}
