import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class PutScreen extends StatefulWidget {
  const PutScreen({super.key});

  @override
  State<PutScreen> createState() => _PutScreenState();
}

class _PutScreenState extends State<PutScreen> {
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
      final res = await ApiStudioClient.instance.put<Map<String, dynamic>>(
        '/posts/1',
        data: {
          'id': 1,
          'title': 'API Studio Updated Title',
          'body': 'Updated via PUT from ApiStudioClient!',
          'userId': 1,
        },
      );
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
      title: 'PUT Request',
      description: 'PUT /posts/1 → expects 200 OK with the fully replaced post echoed back.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send PUT /posts/1', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
