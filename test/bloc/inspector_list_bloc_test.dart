import 'package:bloc_test/bloc_test.dart';
import 'package:api_studio/src/domain/entities/api_log_entity.dart';
import 'package:api_studio/src/domain/repositories/api_log_repository.dart';
import 'package:api_studio/src/domain/usecases/clear_logs_usecase.dart';
import 'package:api_studio/src/domain/usecases/delete_log_usecase.dart';
import 'package:api_studio/src/domain/usecases/get_logs_usecase.dart';
import 'package:api_studio/src/presentation/blocs/inspector_list/inspector_list_bloc.dart';
import 'package:api_studio/src/presentation/blocs/inspector_list/inspector_list_event.dart';
import 'package:api_studio/src/presentation/blocs/inspector_list/inspector_list_state.dart';
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

  InspectorListBloc buildBloc() => InspectorListBloc(
        getLogsUseCase: GetLogsUseCase(repo),
        deleteLogUseCase: DeleteLogUseCase(repo),
        clearLogsUseCase: ClearLogsUseCase(repo),
        repository: repo,
      );

  group('InspectorListBloc', () {
    blocTest<InspectorListBloc, InspectorListState>(
      'emits success with logs on LoadLogsEvent',
      build: buildBloc,
      setUp: () {
        when(() => repo.getLogs(any())).thenAnswer(
          (_) async => [_fakeLog('1'), _fakeLog('2')],
        );
      },
      act: (bloc) => bloc.add(const LoadLogsEvent()),
      expect: () => [
        isA<InspectorListState>()
            .having((s) => s.status, 'status', InspectorListStatus.loading),
        isA<InspectorListState>()
            .having((s) => s.status, 'status', InspectorListStatus.success)
            .having((s) => s.logs.length, 'logs count', 2),
      ],
    );

    blocTest<InspectorListBloc, InspectorListState>(
      'emits failure on repository error',
      build: buildBloc,
      setUp: () {
        when(() => repo.getLogs(any())).thenThrow(Exception('DB error'));
      },
      act: (bloc) => bloc.add(const LoadLogsEvent()),
      expect: () => [
        isA<InspectorListState>()
            .having((s) => s.status, 'status', InspectorListStatus.loading),
        isA<InspectorListState>()
            .having((s) => s.status, 'status', InspectorListStatus.failure),
      ],
    );

    blocTest<InspectorListBloc, InspectorListState>(
      'removes log on DeleteLogEvent',
      build: buildBloc,
      seed: () => InspectorListState(
        status: InspectorListStatus.success,
        logs: [_fakeLog('1'), _fakeLog('2')],
      ),
      setUp: () {
        when(() => repo.deleteLog(any())).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const DeleteLogEvent('1')),
      expect: () => [
        isA<InspectorListState>().having((s) => s.logs.length, 'logs count', 1),
      ],
    );

    blocTest<InspectorListBloc, InspectorListState>(
      'clears all logs on ClearAllLogsEvent',
      build: buildBloc,
      seed: () => InspectorListState(
        status: InspectorListStatus.success,
        logs: [_fakeLog('1'), _fakeLog('2')],
      ),
      setUp: () {
        when(() => repo.clearAllLogs()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const ClearAllLogsEvent()),
      expect: () => [
        isA<InspectorListState>()
            .having((s) => s.logs, 'logs', isEmpty)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );
  });
}
