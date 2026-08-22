import 'package:api_studio/src/domain/entities/api_log_entity.dart';
import 'package:api_studio/src/domain/repositories/api_log_repository.dart';
import 'package:api_studio/src/domain/usecases/clear_logs_usecase.dart';
import 'package:api_studio/src/domain/usecases/delete_log_usecase.dart';
import 'package:api_studio/src/domain/usecases/get_logs_usecase.dart';
import 'package:api_studio/src/presentation/states/inspector_list_state.dart';
import 'package:api_studio/src/presentation/controllers/inspector_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiLogRepository extends Mock implements ApiLogRepository {}

ApiLogEntity _fakeLog(String id) => ApiLogEntity(
      id: id,
      url: 'https://api.example.com/$id',
      method: HttpMethod.get,
      requestHeaders: {},
      queryParams: {},
      timestamp: DateTime(2024),
      responseHeaders: {},
      status: LogStatus.success,
      statusCode: 200,
      durationMs: 120,
    );

void main() {
  late MockApiLogRepository repo;

  setUp(() {
    repo = MockApiLogRepository();
    when(() => repo.watchLogs()).thenAnswer((_) => const Stream.empty());
  });

  setUpAll(() {
    registerFallbackValue(const GetLogsParams());
    registerFallbackValue('');
  });

  InspectorListController buildController() => InspectorListController(
        getLogsUseCase: GetLogsUseCase(repo),
        deleteLogUseCase: DeleteLogUseCase(repo),
        clearLogsUseCase: ClearLogsUseCase(repo),
        repository: repo,
      );

  group('InspectorListController', () {
    test('loads logs with success status', () async {
      when(() => repo.getLogs(any())).thenAnswer(
        (_) async => [_fakeLog('1'), _fakeLog('2')],
      );
      final controller = buildController();
      await controller.loadLogs();
      expect(controller.state.status, InspectorListStatus.success);
      expect(controller.state.logs.length, 2);
      controller.dispose();
    });

    test('sets failure status on repository error', () async {
      when(() => repo.getLogs(any())).thenThrow(Exception('DB error'));
      final controller = buildController();
      await controller.loadLogs();
      expect(controller.state.status, InspectorListStatus.failure);
      controller.dispose();
    });

    test('removes log on deleteLog', () async {
      when(() => repo.getLogs(any())).thenAnswer(
        (_) async => [_fakeLog('1'), _fakeLog('2')],
      );
      when(() => repo.deleteLog(any())).thenAnswer((_) async {});
      final controller = buildController();
      await controller.loadLogs();
      await controller.deleteLog('1');
      expect(controller.state.logs.length, 1);
      controller.dispose();
    });

    test('clears all logs on clearAllLogs', () async {
      when(() => repo.getLogs(any())).thenAnswer(
        (_) async => [_fakeLog('1'), _fakeLog('2')],
      );
      when(() => repo.clearAllLogs()).thenAnswer((_) async {});
      final controller = buildController();
      await controller.loadLogs();
      await controller.clearAllLogs();
      expect(controller.state.logs, isEmpty);
      expect(controller.state.hasReachedMax, true);
      controller.dispose();
    });
  });
}
