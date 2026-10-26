import 'package:api_studio/api_studio.dart';
import 'package:api_studio_http/api_studio_http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final client = ApiStudioHttpClient(inner: http.Client());

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
        title: const Text('api_studio_http'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: () => ApiStudio.showNavigation(context),
          ),
        ],
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => client
              .get(Uri.parse('https://jsonplaceholder.typicode.com/posts/1')),
          child: const Text('GET /posts/1'),
        ),
      ),
    );
  }
}
