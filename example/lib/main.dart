import 'dart:async';

import 'package:api_studio/api_studio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'constants/app_strings.dart';
import 'widgets/failed_api_badge.dart';
import 'widgets/hint_text.dart';
import 'widgets/request_buttons.dart';
import 'widgets/status_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.init(
    enableConnectivityStream: true,
    enableFailedApiStream: true,
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
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
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<int> _failedCountSub;

  String _status = AppStrings.defaultStatus;
  int _failedApiCount = ApiStudio.failedApiCount;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
    _dio.interceptors.add(ApiStudio.interceptor);

    _connectivitySub = ApiStudio.internetConnectivityStream.listen(
      (isConnected) => _showSnackBar(
        isConnected
            ? AppStrings.internetConnected
            : AppStrings.internetDisconnected,
      ),
    );

    _failedCountSub = ApiStudio.failedApiCountStream.listen(
      (count) => setState(() => _failedApiCount = count),
    );
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _failedCountSub.cancel();
    _dio.close();
    super.dispose();
  }

  Future<void> _get() async {
    setState(() => _status = AppStrings.sendingGet);
    try {
      final res = await _dio.get('/posts/1');
      setState(() => _status = 'GET ${res.statusCode}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _post() async {
    setState(() => _status = AppStrings.sendingPost);
    try {
      final res = await _dio.post('/posts', data: {
        'title': AppStrings.postTitle,
        'body': AppStrings.postBody,
        'userId': 1,
      });
      setState(() => _status = 'POST ${res.statusCode}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _fail() async {
    setState(() => _status = AppStrings.sendingFail);
    try {
      await _dio.get('/nonexistent-endpoint-404');
    } catch (_) {
      setState(() => _status = AppStrings.errorCaptured);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          FailedApiBadge(count: _failedApiCount),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: AppStrings.openInspectorTooltip,
            onPressed: () => ApiStudio.show(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusCard(status: _status),
            const SizedBox(height: 24),
            RequestButtons(
              onGet: _get,
              onPost: _post,
              onFail: _fail,
            ),
            const SizedBox(height: 32),
            const HintText(),
          ],
        ),
      ),
    );
  }
}
