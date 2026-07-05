import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class ServerErrorScreen extends StatefulWidget {
  const ServerErrorScreen({super.key});

  @override
  State<ServerErrorScreen> createState() => _ServerErrorScreenState();
}

class _ServerErrorScreenState extends State<ServerErrorScreen> {
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
      await ApiStudioClient.instance
          .get('https://httpstat.us/500');
    } on ServerException catch (e) {
      setState(() {
        _result = 'ServerException caught!\n${e.message}\nStatus: ${e.statusCode}';
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
      title: '5. Server Error (500)',
      description: 'Hits httpstat.us/500. Expects ServerException.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Send to 500 endpoint', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
