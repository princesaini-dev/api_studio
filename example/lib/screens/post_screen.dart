import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
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
      final res = await ApiStudioClient.instance.post<Map<String, dynamic>>(
        '/posts',
        data: {
          'title': 'API Studio Test',
          'body': 'Hello from ApiStudioClient!',
          'userId': 1,
        },
      );
      setState(() =>
          _result = 'Status: ${res.statusCode}\n\n${res.data}');
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
      title: '2. POST Request',
      description: 'POST /posts → expects 201 Created with the new post echoed back.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send POST /posts', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
