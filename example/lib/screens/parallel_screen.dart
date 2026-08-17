import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class ParallelScreen extends StatefulWidget {
  const ParallelScreen({super.key});

  @override
  State<ParallelScreen> createState() => _ParallelScreenState();
}

class _ParallelScreenState extends State<ParallelScreen> {
  bool _loading = false;
  final List<String> _results = [];

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _results.clear();
    });
    final sw = Stopwatch()..start();
    try {
      final client = ApiStudioClient.instance;
      final all = await client.parallel([
        () => client.get<Map<String, dynamic>>('/posts/1'),
        () => client.get<Map<String, dynamic>>('/posts/2'),
        () => client.get<Map<String, dynamic>>('/posts/3'),
        () => client.get<Map<String, dynamic>>('/users/1'),
        () => client.get<Map<String, dynamic>>('/todos/1'),
      ]);
      sw.stop();
      setState(() {
        for (final r in all) {
          _results.add('${r.requestOptions.uri.path} → ${r.statusCode}');
        }
        _results.add('Total time: ${sw.elapsedMilliseconds}ms (parallel)');
      });
    } on ApiStudioException catch (e) {
      setState(() => _results.add('Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '16. Parallel Requests',
      description: 'Fires 5 requests simultaneously using Future.wait.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Fire 5 Parallel Requests',
              onPressed: _run,
              loading: _loading),
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
