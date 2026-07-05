import 'dart:typed_data';

import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = false;
  double _uploadProgress = 0;
  double _downloadProgress = 0;
  String _result = '';

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _uploadProgress = 0;
      _downloadProgress = 0;
      _result = '';
    });
    try {
      // Upload with send progress
      final fakeBytes = Uint8List(1024); // 1KB
      await ApiStudioClient.instance.upload<dynamic>(
        'https://httpbin.org/post',
        files: [
          ApiMultipartFile(
            field: 'data',
            filename: 'progress_test.bin',
            bytes: fakeBytes,
          ),
        ],
        onSendProgress: (sent, total) {
          if (total > 0) setState(() => _uploadProgress = sent / total);
        },
        onReceiveProgress: (received, total) {
          if (total > 0) setState(() => _downloadProgress = received / total);
        },
      );
      setState(() => _result = 'Upload complete! Download complete!');
    } on ApiStudioException catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '10. Progress',
      description: 'Demonstrates onSendProgress and onReceiveProgress callbacks.',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DemoButton(label: 'Start Progress Demo', onPressed: _run, loading: _loading),
            const SizedBox(height: 16),
            const Text('Upload Progress', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 12),
            const Text('Download Progress', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: _downloadProgress),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              ResultCard(label: 'Result', value: _result),
            ],
          ],
        ),
      ),
    );
  }
}
