import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

class CookiesScreen extends StatefulWidget {
  const CookiesScreen({super.key});

  @override
  State<CookiesScreen> createState() => _CookiesScreenState();
}

class _CookiesScreenState extends State<CookiesScreen> {
  final List<String> _log = [];

  void _save() {
    ApiStudioClient.instance.cookies.save('example.com', {
      'session_id': 'abc123',
      'user_pref': 'dark_mode',
    });
    setState(() => _log.add('Saved cookies for example.com'));
  }

  void _read() {
    final cookies = ApiStudioClient.instance.cookies.get('example.com');
    setState(() => _log.add('Read cookies: $cookies'));
  }

  void _delete() {
    ApiStudioClient.instance.cookies.delete('example.com', 'session_id');
    setState(() => _log.add('Deleted session_id for example.com'));
  }

  void _clear() {
    ApiStudioClient.instance.cookies.clear();
    setState(() => _log.add('Cleared all cookies'));
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '11. Cookies',
      description:
          'Demonstrates in-memory cookie jar: save, read, delete, and clear.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _save, child: const Text('Save')),
                FilledButton.tonal(onPressed: _read, child: const Text('Read')),
                OutlinedButton(
                    onPressed: _delete, child: const Text('Delete session_id')),
                OutlinedButton(
                    onPressed: _clear, child: const Text('Clear All')),
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
                child: Text('• ${_log[i]}',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
