import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class NetworkFailureScreen extends StatefulWidget {
  const NetworkFailureScreen({super.key});

  @override
  State<NetworkFailureScreen> createState() => _NetworkFailureScreenState();
}

class _NetworkFailureScreenState extends State<NetworkFailureScreen> {
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
      // Unresolvable host triggers a DNS / network failure.
      await ApiStudioClient.instance
          .get('https://this-host-does-not-exist.invalid/ping');
    } on NetworkException catch (e) {
      setState(() {
        _result = 'NetworkException caught!\n${e.message}';
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
      title: 'Network Failure',
      description: 'Requests an unresolvable host to trigger a DNS/network failure.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Trigger Network Failure', onPressed: _run, loading: _loading),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
