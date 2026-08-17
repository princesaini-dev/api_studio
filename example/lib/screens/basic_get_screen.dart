import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class BasicGetScreen extends StatefulWidget {
  const BasicGetScreen({super.key});

  @override
  State<BasicGetScreen> createState() => _BasicGetScreenState();
}

class _BasicGetScreenState extends State<BasicGetScreen> {
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
      final res =
          await ApiStudioClient.instance.get<Map<String, dynamic>>('/posts/1');
      setState(() => _result = 'Status: ${res.statusCode}\n\n${res.data}');
    } on ApiStudioException catch (e) {
      setState(() {
        _result = e.toString();
        _isError = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '1. Basic GET',
      description: 'GET /posts/1 → expects 200 OK with a JSON post object.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Send GET /posts/1', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
