import 'dart:io';

Future<bool> checkConnectivity() async {
  try {
    final socket = await Socket.connect(
      '8.8.8.8',
      53,
      timeout: const Duration(seconds: 4),
    );
    socket.destroy();
    return true;
  } on SocketException {
    return false;
  } on OSError {
    return false;
  }
}
