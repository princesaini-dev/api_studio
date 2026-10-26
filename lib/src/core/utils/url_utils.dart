/// URL helpers shared by cURL/HAR/Postman export and Edit & Run.
class UrlUtils {
  UrlUtils._();

  /// Merges [params] into the query of [url], preserving repeated keys
  /// (`?a=1&a=2`) and list values. Returns `null` if [url] is not parseable.
  static Uri? mergeQuery(String url, Map<String, dynamic> params) {
    final base = Uri.tryParse(url);
    if (base == null || params.isEmpty) return base;
    final merged = <String, dynamic>{
      for (final e in base.queryParametersAll.entries)
        e.key: e.value.length == 1 ? e.value.first : e.value,
    };
    params.forEach((k, v) {
      merged[k] = v is Iterable ? v.map((e) => '$e').toList() : '$v';
    });
    return base.replace(queryParameters: merged);
  }

  /// Flattens a header value captured as a list into a single string.
  static String headerValue(dynamic value) =>
      value is Iterable ? value.join(', ') : '$value';
}
