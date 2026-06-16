import 'dart:html' as html;

Future<bool> checkConnectivity() async =>
    html.window.navigator.onLine ?? false;
