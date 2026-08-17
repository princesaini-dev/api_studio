import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class ProxyScreen extends StatelessWidget {
  const ProxyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const proxyConfig = ProxyConfig(host: '127.0.0.1', port: 8888);

    return DemoScaffold(
      title: '13. Proxy',
      description:
          'Shows how to configure a custom proxy. The sample proxy (127.0.0.1:8888) is '
          'not running, so the request will fail with a NetworkException — which is the '
          'expected behaviour when no proxy is available.',
      body: _ProxyBody(proxyConfig: proxyConfig),
    );
  }
}

class _ProxyBody extends StatefulWidget {
  final ProxyConfig proxyConfig;
  const _ProxyBody({required this.proxyConfig});

  @override
  State<_ProxyBody> createState() => _ProxyBodyState();
}

class _ProxyBodyState extends State<_ProxyBody> {
  bool _loading = false;
  String _result = '';
  bool _isError = false;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _result = '';
      _isError = false;
    });
    try {
      final config = ClientConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        proxy: widget.proxyConfig,
        connectTimeout: const Duration(seconds: 5),
      );
      ApiStudioClient.initialize(
          baseUrl: 'https://jsonplaceholder.typicode.com', config: config);
      await ApiStudioClient.instance.get('/posts/1');
      setState(() => _result = 'Connected via proxy successfully!');
    } on NetworkException catch (e) {
      setState(() {
        _result =
            'NetworkException (expected — no proxy running):\n${e.message}';
        _isError = true;
      });
    } on ApiStudioException catch (e) {
      setState(() {
        _result = e.toString();
        _isError = true;
      });
    } finally {
      ApiStudio.initClient(baseUrl: 'https://jsonplaceholder.typicode.com');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proxy Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Host: ${widget.proxyConfig.host}'),
                  Text('Port: ${widget.proxyConfig.port}'),
                ],
              ),
            ),
          ),
        ),
        DemoButton(label: 'Send via Proxy', onPressed: _run, loading: _loading),
        if (_result.isNotEmpty)
          ResultCard(label: 'Result', value: _result, isError: _isError),
      ],
    );
  }
}
