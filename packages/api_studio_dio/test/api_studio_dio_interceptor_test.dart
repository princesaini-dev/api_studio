import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:api_studio/api_studio.dart' hide CancelToken, ProgressCallback;
import 'package:api_studio_dio/api_studio_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_path_provider.dart';

/// Mocked Dio transport: each test sets [handler] to decide the outcome.
class FakeAdapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions options)? handler;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (requestStream != null) await requestStream.drain<void>();
    return handler!(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'set-cookie': ['session=abc'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Dio dio;
  late FakeAdapter adapter;
  final logs = <ApiLogEntity>[];

  Future<ApiLogEntity> lastLog() async {
    await pumpEventQueue();
    expect(logs, isNotEmpty, reason: 'expected a captured log');
    return logs.last;
  }

  setUpAll(() async {
    tempDir = installFakePathProvider();
  });

  tearDownAll(() {
    ApiStudio.debugLogListener = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    logs.clear();
    adapter = FakeAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ApiStudioDioInterceptor());
  });

  test('passes requests through untouched before ApiStudio is initialized',
      () async {
    ApiStudio.debugLogListener = logs.add;
    adapter.handler = (_) async => jsonBody({'ok': true});
    final res = await dio.get<dynamic>('/ping');
    expect(res.statusCode, 200);
    expect(adapter.lastOptions!.extra, isEmpty);
    await pumpEventQueue();
    expect(logs, isEmpty);
  });

  group('when enabled', () {
    setUpAll(() async {
      await ApiStudio.initialize(enabled: true, maxBodyBytes: 1024 * 1024);
      ApiStudio.debugLogListener = logs.add;
    });

    test('captures a successful JSON GET with redaction', () async {
      adapter.handler = (_) async => jsonBody({'id': 1, 'token': 'secret-t'});

      await dio.get<dynamic>(
        '/users',
        queryParameters: {'page': 2, 'api_key': 'k-123'},
        options: Options(headers: {
          'Authorization': 'Bearer abc',
          'X-Trace': 'trace-1',
        }),
      );

      final log = await lastLog();
      expect(log.method, HttpMethod.get);
      expect(log.url, startsWith('https://api.example.com/users?'));
      expect(log.url, contains('page=2'));
      expect(log.url, contains('api_key=${RedactionConfig.placeholder}'));
      expect(log.url, isNot(contains('k-123')));
      expect(log.queryParams['page'], 2);
      expect(log.queryParams['api_key'], RedactionConfig.placeholder);
      expect(log.requestHeaders['Authorization'], RedactionConfig.placeholder);
      expect(log.requestHeaders['X-Trace'], 'trace-1');
      expect(log.statusCode, 200);
      expect(log.status, LogStatus.success);
      expect(log.responseHeaders['set-cookie'], RedactionConfig.placeholder);
      expect(log.responseHeaders['content-type'], contains('json'));
      expect(jsonDecode(log.responseBody!), {
        'id': 1,
        'token': RedactionConfig.placeholder,
      });
      expect(log.durationMs, isNotNull);
      expect(log.durationMs, greaterThanOrEqualTo(0));
    });

    test('captures and redacts a JSON request body', () async {
      adapter.handler = (_) async => jsonBody({'ok': true}, status: 201);

      await dio.post<dynamic>('/login', data: {
        'email': 'a@b.c',
        'password': 'hunter2',
        'nested': {'refreshToken': 'r-1'},
      });

      final log = await lastLog();
      expect(log.method, HttpMethod.post);
      final body = jsonDecode(log.requestBody!) as Map<String, dynamic>;
      expect(body['email'], 'a@b.c');
      expect(body['password'], RedactionConfig.placeholder);
      expect(body['nested']['refreshToken'], RedactionConfig.placeholder);
      expect(log.requestBody, isNot(contains('hunter2')));
      expect(log.statusCode, 201);
    });

    test('describes multipart FormData without storing file bytes', () async {
      adapter.handler = (_) async => jsonBody({'uploaded': true});

      await dio.post<dynamic>(
        '/upload',
        data: FormData.fromMap({
          'title': 'avatar',
          'password': 'p',
          'file': MultipartFile.fromBytes(
            List<int>.filled(2048, 7),
            filename: 'a.png',
          ),
        }),
      );

      final log = await lastLog();
      expect(log.isMultipart, isTrue);
      expect(log.requestBody, isNull);
      expect(log.formData!['title'], 'avatar');
      expect(log.formData!['password'], RedactionConfig.placeholder);
      expect(log.formData!['file'], contains('a.png'));
      expect(log.formData!['file'], contains('2048 bytes'));
    });

    test('records HTTP errors from onError with status and body', () async {
      adapter.handler = (_) async => jsonBody({'error': 'boom'}, status: 500);

      await expectLater(
        dio.get<dynamic>('/fail'),
        throwsA(isA<DioException>()),
      );

      final log = await lastLog();
      expect(log.statusCode, 500);
      expect(log.status, LogStatus.error);
      expect(log.responseBody, contains('boom'));
      expect(log.errorMessage, 'HTTP 500');
      expect(log.stackTrace, isNotNull);
    });

    test('records network failures with error and stack trace', () async {
      adapter.handler =
          (_) async => throw const SocketException('Failed host lookup');

      await expectLater(
        dio.get<dynamic>('/offline'),
        throwsA(isA<DioException>()),
      );

      final log = await lastLog();
      expect(log.statusCode, isNull);
      expect(log.status, LogStatus.error);
      expect(log.errorMessage, contains('Failed host lookup'));
      expect(log.stackTrace, isNotEmpty);
    });

    test('labels timeouts', () async {
      adapter.handler = (options) async => throw DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          );

      await expectLater(
        dio.get<dynamic>('/slow'),
        throwsA(isA<DioException>()),
      );

      final log = await lastLog();
      expect(log.status, LogStatus.error);
      expect(log.errorMessage, startsWith('Timeout (receiveTimeout)'));
    });

    test('records cancelled requests with the cancelled status', () async {
      final gate = Completer<ResponseBody>();
      adapter.handler = (_) => gate.future;
      final token = CancelToken();

      final future = dio.get<dynamic>('/cancel-me', cancelToken: token);
      await pumpEventQueue();
      token.cancel('user navigated away');

      await expectLater(future, throwsA(isA<DioException>()));
      gate.complete(jsonBody({}));

      final log = await lastLog();
      expect(log.status, LogStatus.cancelled);
      expect(log.errorMessage, contains('cancelled'));
    });

    test('replaces binary responses with a size placeholder', () async {
      adapter.handler = (_) async => ResponseBody.fromBytes(
            Uint8List(4096),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/octet-stream'],
            },
          );

      await dio.get<List<int>>(
        '/file.bin',
        options: Options(responseType: ResponseType.bytes),
      );

      final log = await lastLog();
      expect(log.responseBody, '[binary data: 4096 bytes]');
      expect(log.responseSizeBytes, 4096);
      expect(log.isTruncated, isFalse);
    });

    test('truncates responses larger than maxBodyBytes', () async {
      final big = 'x' * (1024 * 1024 + 500);
      adapter.handler =
          (_) async => ResponseBody.fromString(big, 200, headers: {
                Headers.contentTypeHeader: ['text/plain'],
              });

      await dio.get<String>(
        '/big',
        options: Options(responseType: ResponseType.plain),
      );

      final log = await lastLog();
      expect(log.isTruncated, isTrue);
      expect(log.responseSizeBytes, big.length);
      expect(log.responseBody!.length, lessThan(big.length));
      expect(log.responseBody, contains('truncated by API Studio'));
    });

    test('filter can skip requests', () async {
      dio.interceptors
        ..clear()
        ..add(
            ApiStudioDioInterceptor(filter: (o) => !o.path.contains('health')));
      adapter.handler = (_) async => jsonBody({'ok': true});

      await dio.get<dynamic>('/health');
      await pumpEventQueue();
      expect(logs, isEmpty);
    });

    test('is a no-op once ApiStudio is disabled', () async {
      await ApiStudio.initialize(enabled: false);
      adapter.handler = (_) async => jsonBody({'ok': true});

      final res = await dio.get<dynamic>('/after-disable');
      expect(res.statusCode, 200);
      expect(adapter.lastOptions!.extra, isEmpty);
      await pumpEventQueue();
      expect(logs, isEmpty);
    });
  });
}
