/// Minimal in-memory cookie jar for [ApiStudioClient].
class ApiCookieJar {
  final Map<String, Map<String, String>> _store = {};

  /// Save [cookies] for the given [domain].
  void save(String domain, Map<String, String> cookies) {
    _store.putIfAbsent(domain, () => {}).addAll(cookies);
  }

  /// Read all cookies for [domain].
  Map<String, String> get(String domain) =>
      Map.unmodifiable(_store[domain] ?? {});

  /// Delete a specific [name] cookie for [domain].
  void delete(String domain, String name) => _store[domain]?.remove(name);

  /// Delete all cookies for [domain].
  void deleteAll(String domain) => _store.remove(domain);

  /// Clear all cookies.
  void clear() => _store.clear();

  /// Build the `Cookie` header value for [domain].
  String? buildHeader(String domain) {
    final cookies = _store[domain];
    if (cookies == null || cookies.isEmpty) return null;
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Parse `Set-Cookie` header values and store them under [domain].
  void parseAndSave(String domain, List<String> setCookieHeaders) {
    for (final header in setCookieHeaders) {
      final parts = header.split(';');
      if (parts.isEmpty) continue;
      final kv = parts.first.split('=');
      if (kv.length < 2) continue;
      final name = kv[0].trim();
      final value = kv.sublist(1).join('=').trim();
      save(domain, {name: value});
    }
  }
}
