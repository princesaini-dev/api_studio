import 'dart:math';

/// Lightweight RFC 4122 v4 UUID generator.
///
/// Replaces the `uuid` package to avoid an extra dependency.
/// Produces standard 36-character UUID strings (8-4-4-4-12 format)
/// with version nibble set to 4 and variant bits set to 10xx.
class UuidGenerator {
  static final Random _random = Random();

  const UuidGenerator();

  /// Generates a random UUID v4 string.
  String v4() {
    // Generate 16 random bytes as unsigned 8-bit integers.
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version nibble to 4 (UUID v4).
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Set variant bits to 10xx (RFC 4122 variant).
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    // Format as 8-4-4-4-12 hex string.
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
