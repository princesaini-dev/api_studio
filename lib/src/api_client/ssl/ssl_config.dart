import 'dart:io';

/// SSL / TLS configuration for [ApiStudioClient].
class SslConfig {
  /// Skip all SSL certificate verification (use only in development).
  final bool ignoreSsl;

  /// Optional list of DER-encoded certificate bytes for certificate pinning.
  final List<List<int>>? pinnedCertificates;

  /// Custom [SecurityContext] (e.g. for self-signed certificates).
  final SecurityContext? securityContext;

  const SslConfig({
    this.ignoreSsl = false,
    this.pinnedCertificates,
    this.securityContext,
  });

  static const defaultConfig = SslConfig();
}
