import 'package:api_studio_dio/api_studio_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

/// Recommended integration: keep your Dio client, add one interceptor.
final Dio demoDio = Dio(
  BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
)..interceptors.add(ApiStudioDioInterceptor());

class DioScreen extends StatefulWidget {
  const DioScreen({super.key});

  @override
  State<DioScreen> createState() => _DioScreenState();
}

class _DioScreenState extends State<DioScreen> {
  bool _loading = false;
  String _result = '';
  bool _isError = false;

  Future<void> _run(Future<Response<dynamic>> Function() request) async {
    setState(() {
      _loading = true;
      _result = '';
      _isError = false;
    });
    try {
      final res = await request();
      setState(() => _result = 'Status: ${res.statusCode}\n\n${res.data}');
    } on DioException catch (e) {
      setState(() {
        _result = '${e.type.name}: ${e.message ?? e.error}';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Dio interceptor',
      description: 'dio.interceptors.add(ApiStudioDioInterceptor()) — every '
          'request below is captured automatically. The Authorization header '
          'and password field are redacted before storage.',
      body: ListView(
        children: [
          DemoButton(
            label: 'GET /posts/1',
            loading: _loading,
            onPressed: () => _run(() => demoDio.get<dynamic>(
                  '/posts/1',
                  options: Options(headers: {'Authorization': 'Bearer demo'}),
                )),
          ),
          DemoButton(
            label: 'POST /posts (with password)',
            loading: _loading,
            onPressed: () => _run(() => demoDio.post<dynamic>(
                  '/posts',
                  data: {'title': 'hello', 'password': 'hunter2'},
                )),
          ),
          DemoButton(
            label: 'GET /does-not-exist (404)',
            loading: _loading,
            onPressed: () =>
                _run(() => demoDio.get<dynamic>('/does-not-exist')),
          ),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
