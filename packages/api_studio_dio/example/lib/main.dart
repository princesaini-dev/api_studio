import 'package:api_studio/api_studio.dart' hide CancelToken, ProgressCallback;
import 'package:api_studio_dio/api_studio_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
  ..interceptors.add(ApiStudioDioInterceptor());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.initialize();
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('api_studio_dio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: () => ApiStudio.showNavigation(context),
          ),
        ],
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => dio.get<dynamic>('/posts/1'),
          child: const Text('GET /posts/1'),
        ),
      ),
    );
  }
}
