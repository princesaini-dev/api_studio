import 'dart:typed_data';

import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
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
      // Simulate a small PNG (1x1 transparent pixel) as upload payload
      final fakeImageBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);

      final res = await ApiStudioClient.instance.upload<Map<String, dynamic>>(
        'https://httpbin.org/post',
        files: [
          ApiMultipartFile(
            field: 'file',
            filename: 'test_image.png',
            bytes: fakeImageBytes,
            contentType: 'image/png',
          ),
        ],
        formFields: {'description': 'API Studio upload test'},
        onSendProgress: (sent, total) {
          if (total > 0) setState(() => _progress = sent / total);
        },
      );
      setState(() => _result = 'Status: ${res.statusCode}\nUpload successful!');
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
      title: '8. Upload',
      description:
          'Uploads a fake image file via multipart/form-data to httpbin.org/post.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(label: 'Upload File', onPressed: _run, loading: _loading),
          if (_loading || _progress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(value: _progress),
            ),
          if (_result.isNotEmpty)
            ResultCard(label: 'Result', value: _result, isError: _isError),
        ],
      ),
    );
  }
}
