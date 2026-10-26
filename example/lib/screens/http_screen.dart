import 'package:api_studio_http/api_studio_http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/demo_scaffold.dart';

/// `package:http` integration: wrap your existing client.
final http.Client demoHttpClient = ApiStudioHttpClient(inner: http.Client());

class HttpScreen extends StatefulWidget {
  const HttpScreen({super.key});

  @override
  State<HttpScreen> createState() => _HttpScreenState();
}

class _HttpScreenState extends State<HttpScreen> {
  bool _loading = false;
  String _result = '';
  bool _isError = false;

  Future<void> _run(Future<http.Response> Function() request) async {
    setState(() {
      _loading = true;
      _result = '';
      _isError = false;
    });
    try {
      final res = await request();
      setState(() {
        _result = 'Status: ${res.statusCode}\n\n${res.body}';
        _isError = res.statusCode >= 400;
      });
    } catch (e) {
      setState(() {
        _result = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const base = 'https://jsonplaceholder.typicode.com';
    return DemoScaffold(
      title: 'package:http client',
      description: 'ApiStudioHttpClient(inner: http.Client()) — a drop-in '
          'http.Client that captures every request.',
      body: ListView(
        children: [
          DemoButton(
            label: 'GET /users/1',
            loading: _loading,
            onPressed: () =>
                _run(() => demoHttpClient.get(Uri.parse('$base/users/1'))),
          ),
          DemoButton(
            label: 'POST /posts (form, with token)',
            loading: _loading,
            onPressed: () => _run(() => demoHttpClient.post(
                  Uri.parse('$base/posts'),
                  body: {'title': 'hi', 'token': 'secret-token'},
                )),
          ),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
