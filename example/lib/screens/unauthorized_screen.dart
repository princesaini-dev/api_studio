import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class UnauthorizedScreen extends StatefulWidget {
  const UnauthorizedScreen({super.key});

  @override
  State<UnauthorizedScreen> createState() => _UnauthorizedScreenState();
}

class _UnauthorizedScreenState extends State<UnauthorizedScreen> {
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
      // httpstat.us returns the status code you request
      final client = ApiStudioClient.instance;
      await client.get('https://httpstat.us/401',
          headers: {'Accept': 'application/json'});
    } on UnauthorizedException catch (e) {
      setState(() {
        _result =
            'UnauthorizedException caught!\n${e.message}\nStatus: ${e.statusCode}';
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
      title: '4. Unauthorized (401)',
      description: 'Hits httpstat.us/401. Expects UnauthorizedException.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Send to 401 endpoint',
              onPressed: _run,
              loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
