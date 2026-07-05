import 'dart:async';

import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';

import 'screens/basic_get_screen.dart';
import 'screens/post_screen.dart';
import 'screens/error_screen.dart';
import 'screens/unauthorized_screen.dart';
import 'screens/server_error_screen.dart';
import 'screens/timeout_screen.dart';
import 'screens/retry_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/download_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/cookies_screen.dart';
import 'screens/cache_screen.dart';
import 'screens/proxy_screen.dart';
import 'screens/ssl_screen.dart';
import 'screens/cancellation_screen.dart';
import 'screens/parallel_screen.dart';
import 'screens/sequential_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/duplicate_screen.dart';
import 'screens/interceptor_screen.dart';
import 'widgets/failed_api_badge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.init(
    enableConnectivityStream: true,
    enableFailedApiStream: true,
  );
  ApiStudio.initClient(baseUrl: 'https://jsonplaceholder.typicode.com');
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Studio Demo',
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
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<int> _failedCountSub;
  int _failedApiCount = ApiStudio.failedApiCount;

  static const _demos = <_DemoItem>[
    _DemoItem('1. Basic GET', Icons.download_rounded, Colors.blue),
    _DemoItem('2. POST Request', Icons.upload_rounded, Colors.green),
    _DemoItem('3. Error (400)', Icons.warning_rounded, Colors.orange),
    _DemoItem('4. Unauthorized (401)', Icons.lock_rounded, Colors.red),
    _DemoItem('5. Server Error (500)', Icons.cloud_off_rounded, Colors.red),
    _DemoItem('6. Timeout', Icons.timer_off_rounded, Colors.amber),
    _DemoItem('7. Retry', Icons.replay_rounded, Colors.teal),
    _DemoItem('8. Upload', Icons.cloud_upload_rounded, Colors.purple),
    _DemoItem('9. Download', Icons.cloud_download_rounded, Colors.indigo),
    _DemoItem('10. Progress', Icons.linear_scale_rounded, Colors.cyan),
    _DemoItem('11. Cookies', Icons.cookie_rounded, Colors.brown),
    _DemoItem('12. Cache', Icons.storage_rounded, Colors.blueGrey),
    _DemoItem('13. Proxy', Icons.router_rounded, Colors.deepOrange),
    _DemoItem('14. SSL', Icons.security_rounded, Colors.green),
    _DemoItem('15. Cancellation', Icons.cancel_rounded, Colors.pink),
    _DemoItem('16. Parallel Requests', Icons.sync_alt_rounded, Colors.blue),
    _DemoItem('17. Sequential Requests', Icons.list_rounded, Colors.teal),
    _DemoItem(
        '18. Batch Requests', Icons.batch_prediction_rounded, Colors.orange),
    _DemoItem(
        '19. Duplicate Prevention', Icons.filter_none_rounded, Colors.purple),
    _DemoItem('20. Interceptors', Icons.layers_rounded, Colors.indigo),
  ];

  static final _screens = <Widget>[
    const BasicGetScreen(),
    const PostScreen(),
    const ErrorScreen(),
    const UnauthorizedScreen(),
    const ServerErrorScreen(),
    const TimeoutScreen(),
    const RetryScreen(),
    const UploadScreen(),
    const DownloadScreen(),
    const ProgressScreen(),
    const CookiesScreen(),
    const CacheScreen(),
    const ProxyScreen(),
    const SslScreen(),
    const CancellationScreen(),
    const ParallelScreen(),
    const SequentialScreen(),
    const BatchScreen(),
    const DuplicateScreen(),
    const InterceptorScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _connectivitySub = ApiStudio.internetConnectivityStream.listen(
      (connected) => _snack(connected ? 'Internet Connected' : 'No Internet'),
    );
    _failedCountSub = ApiStudio.failedApiCountStream.listen(
      (c) => setState(() => _failedApiCount = c),
    );
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _failedCountSub.cancel();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Studio Demo'),
        actions: [
          FailedApiBadge(count: _failedApiCount),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Open Inspector',
            onPressed: () => ApiStudio.show(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final item = _demos[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.color.withValues(alpha: 0.15),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              title: Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => _screens[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoItem {
  final String title;
  final IconData icon;
  final Color color;
  const _DemoItem(this.title, this.icon, this.color);
}
