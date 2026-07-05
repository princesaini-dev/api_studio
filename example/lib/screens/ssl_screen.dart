import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class SslScreen extends StatefulWidget {
  const SslScreen({super.key});

  @override
  State<SslScreen> createState() => _SslScreenState();
}

class _SslScreenState extends State<SslScreen> {
  bool _loading = false;
  String _result = '';
  bool _isError = false;

  Future<void> _runDefault() async {
    setState(() { _loading = true; _result = ''; _isError = false; });
    try {
      final res = await ApiStudioClient.instance
          .get<Map<String, dynamic>>('/posts/1');
      setState(() => _result = 'Default SSL OK — Status: ${res.statusCode}');
    } on ApiStudioException catch (e) {
      setState(() { _result = e.toString(); _isError = true; });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _runIgnoreSsl() async {
    setState(() { _loading = true; _result = ''; _isError = false; });
    try {
      final config = ClientConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        ssl: const SslConfig(ignoreSsl: true),
      );
      ApiStudioClient.initialize(
          baseUrl: 'https://jsonplaceholder.typicode.com', config: config);
      final res = await ApiStudioClient.instance
          .get<Map<String, dynamic>>('/posts/1');
      setState(() =>
          _result = 'Ignore-SSL OK — Status: ${res.statusCode}\n(Certificate not verified)');
    } on ApiStudioException catch (e) {
      setState(() { _result = e.toString(); _isError = true; });
    } finally {
      ApiStudio.initClient(baseUrl: 'https://jsonplaceholder.typicode.com');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '14. SSL',
      description: 'Demonstrates default SSL verification and ignoreSsl mode.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Default SSL (verified)',
              onPressed: _loading ? null : _runDefault,
              loading: _loading),
          DemoButton(
              label: 'Ignore SSL (skip verification)',
              onPressed: _loading ? null : _runIgnoreSsl,
              loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
