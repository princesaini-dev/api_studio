import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool _loading = false;
  String _result = '';
  bool _isError = false;
  double _progress = 0;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _result = '';
      _isError = false;
      _progress = 0;
    });
    try {
      final res = await ApiStudioClient.instance.download(
        'https://jsonplaceholder.typicode.com/todos/1',
        onReceiveProgress: (received, total) {
          if (total > 0) setState(() => _progress = received / total);
        },
      );
      final bytes = res.data ?? [];
      setState(() => _result =
          'Status: ${res.statusCode}\nReceived ${bytes.length} bytes');
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
      title: '9. Download',
      description:
          'Downloads a JSON file as raw bytes with receive-progress tracking.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Download File', onPressed: _run, loading: _loading),
          if (_loading || _progress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress),
            ),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
