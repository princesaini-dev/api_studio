import 'dart:io';

Future<bool> checkConnectivity() async {
  try {
    final socket = await Socket.connect(
      'cloudflare.com',
      443,
      timeout: const Duration(seconds: 1),
    );

    socket.destroy();
    return true;
  } on SocketException {
    return false;
  } catch (_) {
    return false;
  }
}
