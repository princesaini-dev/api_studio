import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
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
      await ApiStudioClient.instance.get('/nonexistent-endpoint-that-returns-404');
    } on BadResponseException catch (e) {
      setState(() {
        _result = 'BadResponseException caught!\n${e.message}\nStatus: ${e.statusCode}';
        _isError = true;
      });
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
      title: '3. Error (400)',
      description: 'Calls a non-existent endpoint. Expects a 404 BadResponseException to be thrown and captured.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send request to bad endpoint', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Error captured', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
