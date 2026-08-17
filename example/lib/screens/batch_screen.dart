import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  bool _loading = false;
  final List<String> _results = [];

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _results.clear();
    });
    final client = ApiStudioClient.instance;

    final batch = [
      () => client.get<dynamic>('/posts/1'),
      () => client.get<dynamic>('/posts/2'),
      () => client.get<dynamic>('/posts/3'),
      () => client.get<dynamic>('/posts/4'),
      () => client.get<dynamic>('/posts/5'),
      () => client.get<dynamic>('/comments/1'),
      () => client.get<dynamic>('/albums/1'),
    ];

    try {
      setState(
          () => _results.add('Executing batch of ${batch.length} requests...'));
      final results = await client.parallel(batch);
      for (final r in results) {
        setState(() =>
            _results.add('${r.requestOptions.uri.path} → ${r.statusCode}'));
      }
      setState(() => _results.add('Batch complete ✓'));
    } on ApiStudioException catch (e) {
      setState(() => _results.add('Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '18. Batch Requests',
      description:
          'Fires a batch of 7 requests simultaneously and shows all results.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Execute Batch', onPressed: _run, loading: _loading),
          ..._results.map((r) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text('• $r',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
