import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class SequentialScreen extends StatefulWidget {
  const SequentialScreen({super.key});

  @override
  State<SequentialScreen> createState() => _SequentialScreenState();
}

class _SequentialScreenState extends State<SequentialScreen> {
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

      // Step 1: Get user
      setState(() => _results.add('Step 1: fetching user /users/1...'));
      final userRes = await client.get<Map<String, dynamic>>('/users/1');
      final userId = (userRes.data?['id'] as int?) ?? 1;
      setState(() => _results.add('  ✓ Got user id=$userId'));

      // Step 2: Get posts by that user
      setState(
          () => _results.add('Step 2: fetching posts for userId=$userId...'));
      final postsRes = await client.get<List<dynamic>>(
        '/posts',
        queryParameters: {'userId': userId.toString()},
      );
      final count = (postsRes.data)?.length ?? 0;
      setState(() => _results.add('  ✓ Got $count posts'));

      // Step 3: Get first post details
      setState(() => _results.add('Step 3: fetching first post /posts/1...'));
      final postRes = await client.get<Map<String, dynamic>>('/posts/1');
      final title = postRes.data?['title'] as String? ?? '';
      setState(() => _results.add('  ✓ Post title: "$title"'));

      sw.stop();
      setState(() =>
          _results.add('Total time: ${sw.elapsedMilliseconds}ms (sequential)'));
    } on ApiStudioException catch (e) {
      setState(() => _results.add('Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '17. Sequential Requests',
      description:
          'Executes 3 dependent API calls in sequence: user → posts → post detail.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoButton(
              label: 'Run Sequential Chain',
              onPressed: _run,
              loading: _loading),
          ..._results.map((r) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text(r,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
