import 'package:web/web.dart' as web;

Future<bool> checkConnectivity() async {
  return web.window.navigator.onLine;
}
