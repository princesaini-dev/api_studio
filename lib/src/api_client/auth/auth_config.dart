import 'dart:convert';

import '../enums/auth_type_enum.dart';

/// Provides authentication headers that are injected before every request.
abstract class AuthConfig {
  const AuthConfig();

  AuthType get type;

  /// Returns the auth-related headers to merge into the request.
  Map<String, String> buildHeaders();

  factory AuthConfig.bearer(String token) => _BearerAuth(token);

  factory AuthConfig.jwt(String token) => _JwtAuth(token);

  factory AuthConfig.apiKey({
    required String key,
    String headerName = 'X-API-Key',
  }) =>
      _ApiKeyAuth(key: key, headerName: headerName);

  factory AuthConfig.basic({
    required String username,
    required String password,
  }) =>
      _BasicAuth(username: username, password: password);
}

class _BearerAuth extends AuthConfig {
  final String token;
  const _BearerAuth(this.token);

  @override
  AuthType get type => AuthType.bearer;

  @override
  Map<String, String> buildHeaders() => {'Authorization': 'Bearer $token'};
}

class _JwtAuth extends AuthConfig {
  final String token;
  const _JwtAuth(this.token);

  @override
  AuthType get type => AuthType.jwt;

  @override
  Map<String, String> buildHeaders() => {'Authorization': 'Bearer $token'};
}

class _ApiKeyAuth extends AuthConfig {
  final String key;
  final String headerName;
  const _ApiKeyAuth({required this.key, required this.headerName});

  @override
  AuthType get type => AuthType.apiKey;

  @override
  Map<String, String> buildHeaders() => {headerName: key};
}

class _BasicAuth extends AuthConfig {
  final String username;
  final String password;
  const _BasicAuth({required this.username, required this.password});

  @override
  AuthType get type => AuthType.basic;

  @override
  Map<String, String> buildHeaders() {
    final encoded = base64Encode(utf8.encode('$username:$password'));
    return {'Authorization': 'Basic $encoded'};
  }
}
