import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class TimeoutScreen extends StatefulWidget {
  const TimeoutScreen({super.key});

  @override
  State<TimeoutScreen> createState() => _TimeoutScreenState();
}

class _TimeoutScreenState extends State<TimeoutScreen> {
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
      // httpstat.us/200?sleep=5000 delays 5 seconds; our timeout is 2 seconds
      await ApiStudioClient.instance.get(
        'https://httpstat.us/200',
        queryParameters: {'sleep': '5000'},
        receiveTimeout: const Duration(seconds: 2),
      );
    } on TimeoutException catch (e) {
      setState(() {
        _result = 'TimeoutException caught!\n${e.message}';
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
      title: '6. Timeout',
      description:
          'Sends a request with a 2s timeout to a 5s delayed endpoint.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Trigger Timeout', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
