import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class InterceptorScreen extends StatefulWidget {
  const InterceptorScreen({super.key});

  @override
  State<InterceptorScreen> createState() => _InterceptorScreenState();
}

class _InterceptorScreenState extends State<InterceptorScreen> {
  bool _loading = false;
  final List<_LogEntry> _log = [];

  void _addLog(String phase, String msg, {bool isError = false}) {
    if (mounted)
      setState(() => _log.add(_LogEntry(phase, msg, isError: isError)));
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _log.clear();
    });

    final requestInterceptor =
        _DemoRequestInterceptor(onLog: (m) => _addLog('REQUEST', m));
    final responseInterceptor =
        _DemoResponseInterceptor(onLog: (m) => _addLog('RESPONSE', m));
    final errorInterceptor =
        _DemoErrorInterceptor(onLog: (m) => _addLog('ERROR', m, isError: true));

    ApiStudioClient.instance.interceptors
      ..clear()
      ..add(requestInterceptor)
      ..add(responseInterceptor)
      ..add(errorInterceptor);

    try {
      // Successful request
      _addLog('INFO', 'Sending GET /posts/1...');
      await ApiStudioClient.instance.get<Map<String, dynamic>>('/posts/1');

      // Failing request to trigger error interceptor
      _addLog('INFO', 'Sending GET to bad endpoint...');
      await ApiStudioClient.instance.get('/nonexistent-404');
    } on ApiStudioException {
      // logged by interceptor
    } finally {
      ApiStudioClient.instance.interceptors.clear();
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '20. Interceptors',
      description:
          'Attaches request, response, and error interceptors then makes two requests.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Run Interceptor Demo',
              onPressed: _run,
              loading: _loading),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _log.length,
              itemBuilder: (_, i) {
                final e = _log[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: e.isError
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(e.phase,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: e.isError
                                  ? Colors.red.shade800
                                  : Colors.blue.shade800,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.msg,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String phase;
  final String msg;
  final bool isError;
  const _LogEntry(this.phase, this.msg, {this.isError = false});
}

class _DemoRequestInterceptor extends ApiInterceptor {
  final void Function(String) onLog;
  const _DemoRequestInterceptor({required this.onLog});

  @override
  void onRequest(ApiRequestOptions options, RequestInterceptorHandler handler) {
    onLog('${options.method.value} ${options.uri}');
    onLog('Headers: ${options.headers.keys.join(', ')}');
    handler.next(options.copyWith(
      headers: {...options.headers, 'X-Demo-Interceptor': 'true'},
    ));
  }
}

class _DemoResponseInterceptor extends ApiInterceptor {
  final void Function(String) onLog;
  const _DemoResponseInterceptor({required this.onLog});

  @override
  void onResponse<T>(
      ApiResponse<T> response, ResponseInterceptorHandler<T> handler) {
    onLog('Status: ${response.statusCode}');
    onLog('Has data: ${response.hasData}');
    handler.next(response);
  }
}

class _DemoErrorInterceptor extends ApiInterceptor {
  final void Function(String) onLog;
  const _DemoErrorInterceptor({required this.onLog});

  @override
  void onError(ApiStudioException error, ErrorInterceptorHandler handler) {
    onLog('${error.runtimeType}: ${error.message}');
    handler.next(error);
  }
}
