import 'package:dio/dio.dart';
import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.init();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Studio Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Dio _dio;
  String _status = 'Tap a button to fire a request';

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
    _dio.interceptors.add(ApiStudio.interceptor);
  }

  Future<void> _get() async {
    setState(() => _status = 'Sending GET...');
    try {
      final res = await _dio.get('/posts/1');
      setState(() => _status = 'GET ${res.statusCode}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _post() async {
    setState(() => _status = 'Sending POST...');
    try {
      final res = await _dio.post('/posts', data: {
        'title': 'API Studio Test',
        'body': 'Hello from api_studio!',
        'userId': 1,
      });
      setState(() => _status = 'POST ${res.statusCode}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _fail() async {
    setState(() => _status = 'Sending failing request...');
    try {
      await _dio.get('/nonexistent-endpoint-404');
    } catch (e) {
      setState(() => _status = 'Error captured in inspector');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Studio Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Open Inspector',
            onPressed: () => ApiStudio.show(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_status, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('GET /posts/1'),
              onPressed: _get,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.upload_rounded),
              label: const Text('POST /posts'),
              onPressed: _post,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Trigger 404'),
              onPressed: _fail,
            ),
            const SizedBox(height: 32),
            const Text(
              'Tap the bug icon in the app bar to open the API Inspector dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
