import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class PatchScreen extends StatefulWidget {
  const PatchScreen({super.key});

  @override
  State<PatchScreen> createState() => _PatchScreenState();
}

class _PatchScreenState extends State<PatchScreen> {
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
      final res = await ApiStudioClient.instance.patch<Map<String, dynamic>>(
        '/posts/1',
        data: {'title': 'API Studio Patched Title'},
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
      title: 'PATCH Request',
      description: 'PATCH /posts/1 → expects 200 OK with a partially updated post echoed back.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send PATCH /posts/1', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Response', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
