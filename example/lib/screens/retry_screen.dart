import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class RetryScreen extends StatefulWidget {
  const RetryScreen({super.key});

  @override
  State<RetryScreen> createState() => _RetryScreenState();
}

class _RetryScreenState extends State<RetryScreen> {
  bool _loading = false;
  final List<String> _log = [];

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _log.clear();
    });

    int attempt = 0;

    // Create a one-shot client with retry config and an interceptor that logs
    final config = ClientConfig(
      baseUrl: 'https://httpstat.us',
      retry: RetryConfig(
        maxAttempts: 3,
        delay: const Duration(milliseconds: 500),
        retryOn: (_) => true, // retry on all errors
      ),
    );

    ApiStudioClient.initialize(config: config, baseUrl: 'https://httpstat.us');
    final client = ApiStudioClient.instance;

    client.interceptors.add(_LogInterceptor(
      onAttempt: () {
        attempt++;
        setState(() => _log.add('Attempt $attempt → sending request'));
      },
    ));

    try {
      // 503 will be treated as ServerException → retried
      await client.get('/503');
    } on ServerException catch (e) {
      setState(() => _log.add('Final failure: ${e.message}'));
    } on ApiStudioException catch (e) {
      setState(() => _log.add('Error: $e'));
    } finally {
      // Restore original client
      ApiStudio.initClient(baseUrl: 'https://jsonplaceholder.typicode.com');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '7. Retry',
      description:
          'Sends to /503 with RetryConfig(maxAttempts: 3). Shows retry attempts in the log.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Start Retry Demo', onPressed: _run, loading: _loading),
          const SizedBox(height: 8),
          ..._log.map((line) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text('• $line',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              )),
        ],
      ),
    );
  }
}

class _LogInterceptor extends ApiInterceptor {
  final VoidCallback onAttempt;
  const _LogInterceptor({required this.onAttempt});

  @override
  void onRequest(ApiRequestOptions options, RequestInterceptorHandler handler) {
    onAttempt();
    handler.next(options);
  }
}
