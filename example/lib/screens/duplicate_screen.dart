import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class DuplicateScreen extends StatefulWidget {
  const DuplicateScreen({super.key});

  @override
  State<DuplicateScreen> createState() => _DuplicateScreenState();
}

class _DuplicateScreenState extends State<DuplicateScreen> {
  bool _loading = false;
  final List<String> _log = [];

  Future<void> _runAllow() => _runWith(DuplicateRequestStrategy.allow, 'allow');
  Future<void> _runIgnore() =>
      _runWith(DuplicateRequestStrategy.ignore, 'ignore');
  Future<void> _runCancel() =>
      _runWith(DuplicateRequestStrategy.cancelPrevious, 'cancelPrevious');

  Future<void> _runWith(DuplicateRequestStrategy strategy, String name) async {
    setState(() {
      _loading = true;
      _log.clear();
      _log.add('Strategy: $name');
    });

    final config = ClientConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      duplicateStrategy: strategy,
    );
    ApiStudioClient.initialize(
        baseUrl: 'https://jsonplaceholder.typicode.com', config: config);
    final client = ApiStudioClient.instance;

    // Fire 3 identical requests simultaneously
    final futures = List.generate(
      3,
      (i) => client
          .get<Map<String, dynamic>>('/posts/1')
          .then((r) =>
              setState(() => _log.add('Request ${i + 1}: ${r.statusCode}')))
          .catchError((e) =>
              setState(() => _log.add('Request ${i + 1}: ${e.runtimeType}'))),
    );

    await Future.wait(futures);
    ApiStudio.initClient(baseUrl: 'https://jsonplaceholder.typicode.com');
    setState(() {
      _loading = false;
      _log.add('Done.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '19. Duplicate Prevention',
      description:
          'Fires 3 identical requests simultaneously with different strategies.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                    onPressed: _loading ? null : _runAllow,
                    child: const Text('Allow')),
                FilledButton.tonal(
                    onPressed: _loading ? null : _runIgnore,
                    child: const Text('Ignore Dup')),
                OutlinedButton(
                    onPressed: _loading ? null : _runCancel,
                    child: const Text('Cancel Previous')),
              ],
            ),
          ),
          const Divider(),
          ..._log.map((l) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text('• $l',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
