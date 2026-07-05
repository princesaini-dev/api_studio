/// Proxy configuration for [ApiStudioClient].
class ProxyConfig {
  final String host;
  final int port;
  final String? username;
  final String? password;

  const ProxyConfig({
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  /// Returns the proxy URL in the format expected by [HttpClient.findProxy].
  String get proxyUrl => 'PROXY $host:$port';
}
