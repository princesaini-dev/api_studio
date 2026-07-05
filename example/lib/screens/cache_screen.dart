import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class CacheScreen extends StatefulWidget {
  const CacheScreen({super.key});

  @override
  State<CacheScreen> createState() => _CacheScreenState();
}

class _CacheScreenState extends State<CacheScreen> {
  bool _loading = false;
  final List<String> _log = [];

  Future<void> _firstRequest() async {
    setState(() {
      _loading = true;
      _log.add('→ Request 1: fetching from network...');
    });
    final sw = Stopwatch()..start();
    try {
      await ApiStudioClient.instance.get<Map<String, dynamic>>(
        '/posts/1',
        cachePolicy: const CachePolicy(enabled: true, ttl: Duration(minutes: 2)),
      );
      sw.stop();
      setState(() => _log.add('✓ Network response in ${sw.elapsedMilliseconds}ms (cached)'));
    } on ApiStudioException catch (e) {
      setState(() => _log.add('✗ Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _secondRequest() async {
    setState(() {
      _loading = true;
      _log.add('→ Request 2: fetching (should be cached)...');
    });
    final sw = Stopwatch()..start();
    try {
      await ApiStudioClient.instance.get<Map<String, dynamic>>(
        '/posts/1',
        cachePolicy: const CachePolicy(enabled: true, ttl: Duration(minutes: 2)),
      );
      sw.stop();
      setState(() => _log.add('✓ Cache hit in ${sw.elapsedMilliseconds}ms'));
    } on ApiStudioException catch (e) {
      setState(() => _log.add('✗ Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _loading = true;
      _log.add('→ Force refresh: bypassing cache...');
    });
    final sw = Stopwatch()..start();
    try {
      await ApiStudioClient.instance.get<Map<String, dynamic>>(
        '/posts/1',
        cachePolicy: const CachePolicy(
            enabled: true, ttl: Duration(minutes: 2), forceRefresh: true),
      );
      sw.stop();
      setState(() => _log.add('✓ Fresh network response in ${sw.elapsedMilliseconds}ms'));
    } on ApiStudioException catch (e) {
      setState(() => _log.add('✗ Error: $e'));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '12. Cache',
      description: 'First request goes to network. Second hits cache. Force refresh bypasses it.',
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
                    onPressed: _loading ? null : _firstRequest,
                    child: const Text('1st Request')),
                FilledButton.tonal(
                    onPressed: _loading ? null : _secondRequest,
                    child: const Text('2nd (cached)')),
                OutlinedButton(
                    onPressed: _loading ? null : _forceRefresh,
                    child: const Text('Force Refresh')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(_log[i],
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
