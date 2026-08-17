import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class CancellationScreen extends StatefulWidget {
  const CancellationScreen({super.key});

  @override
  State<CancellationScreen> createState() => _CancellationScreenState();
}

class _CancellationScreenState extends State<CancellationScreen> {
  CancelToken? _token;
  bool _loading = false;
  String _result = '';
  bool _isError = false;

  Future<void> _start() async {
    final token = CancelToken();
    setState(() {
      _token = token;
      _loading = true;
      _result = 'Request started — tap Cancel to abort...';
      _isError = false;
    });
    try {
      // 8 second delayed response — plenty of time to cancel
      await ApiStudioClient.instance.get(
        'https://httpstat.us/200',
        queryParameters: {'sleep': '8000'},
        cancelToken: token,
        receiveTimeout: const Duration(seconds: 15),
      );
      setState(() => _result = 'Request completed (not cancelled)');
    } on CancelledException catch (e) {
      setState(() {
        _result = 'CancelledException!\n${e.message}';
        _isError = true;
      });
    } on ApiStudioException catch (e) {
      setState(() {
        _result = e.toString();
        _isError = true;
      });
    } finally {
      setState(() {
        _loading = false;
        _token = null;
      });
    }
  }

  void _cancel() {
    _token?.cancel('User tapped Cancel');
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '15. Cancellation',
      description: 'Starts a long request then cancels it via CancelToken.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Start Long Request',
              onPressed: _loading ? null : _start,
              loading: _loading),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: _loading ? _cancel : null,
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Cancel Request'),
            ),
          ),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
