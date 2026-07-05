import '../models/api_response.dart';

/// A simple in-memory cache entry.
class _CacheEntry {
  final ApiResponse<dynamic> response;
  final DateTime expiresAt;

  _CacheEntry({required this.response, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Lightweight in-memory cache for [ApiStudioClient] responses.
///
/// Keys are derived from the request URI + method.
class MemoryCacheStore {
  final Map<String, _CacheEntry> _store = {};

  /// Store [response] under [key] for [ttl] duration.
  void put(String key, ApiResponse<dynamic> response, Duration ttl) {
    _store[key] = _CacheEntry(
      response: response,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Retrieve cached response for [key], or `null` if absent / expired.
  ApiResponse<dynamic>? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.response;
  }

  /// Remove entry for [key].
  void invalidate(String key) => _store.remove(key);

  /// Clear all entries.
  void clear() => _store.clear();

  int get size => _store.length;
}

/// Per-request cache policy.
class CachePolicy {
  /// Whether caching is enabled for this request.
  final bool enabled;

  /// TTL for the cached response.
  final Duration ttl;

  /// Force a fresh network request even if a cached response exists.
  final bool forceRefresh;

  const CachePolicy({
    this.enabled = true,
    this.ttl = const Duration(minutes: 5),
    this.forceRefresh = false,
  });

  static const disabled = CachePolicy(enabled: false);
}
