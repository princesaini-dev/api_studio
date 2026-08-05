import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class DeleteScreen extends StatefulWidget {
  const DeleteScreen({super.key});

  @override
  State<DeleteScreen> createState() => _DeleteScreenState();
}

class _DeleteScreenState extends State<DeleteScreen> {
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
      final res = await ApiStudioClient.instance
          .delete<Map<String, dynamic>>('/posts/1');
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
      title: 'DELETE Request',
      description: 'DELETE /posts/1 → expects 200 OK confirming deletion.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send DELETE /posts/1', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
