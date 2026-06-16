extension StringExtensions on String {
  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null && (uri.hasScheme) && uri.host.isNotEmpty;
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
