import '../auth/auth_config.dart';
import '../enums/duplicate_strategy_enum.dart';
import '../proxy/proxy_config.dart';
import '../retry/retry_config.dart';
import '../ssl/ssl_config.dart';

/// Global configuration for [ApiStudioClient].
class ClientConfig {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final AuthConfig? auth;
  final RetryConfig? retry;
  final SslConfig ssl;
  final ProxyConfig? proxy;
  final bool enableCookies;
  final bool enableLogging;
  final DuplicateRequestStrategy duplicateStrategy;
  final int maxConcurrentRequests;

  const ClientConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.auth,
    this.retry,
    this.ssl = SslConfig.defaultConfig,
    this.proxy,
    this.enableCookies = false,
    this.enableLogging = true,
    this.duplicateStrategy = DuplicateRequestStrategy.allow,
    this.maxConcurrentRequests = 0,
  });
}
