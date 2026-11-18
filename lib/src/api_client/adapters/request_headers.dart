/// Merges client-wide [defaults] with a request's own [perRequest] headers
/// into one header per name, matching names case-insensitively.
///
/// A per-request value replaces a default with the same name, and the
/// per-request spelling of the name is kept.
///
/// The web adapter needs this because `XMLHttpRequest.setRequestHeader`
/// appends to a header that is already set instead of replacing it: setting
/// `Content-Type: application/json` twice sends
/// `application/json, application/json`, which servers such as FastAPI do not
/// treat as JSON.
Map<String, String> mergeRequestHeaders(
  Map<String, String> defaults,
  Map<String, dynamic> perRequest,
) {
  final merged = <String, String>{};
  final nameByLower = <String, String>{};

  void put(String name, String value) {
    final previous = nameByLower[name.toLowerCase()];
    if (previous != null) merged.remove(previous);
    nameByLower[name.toLowerCase()] = name;
    merged[name] = value;
  }

  for (final e in defaults.entries) {
    put(e.key, e.value);
  }
  for (final e in perRequest.entries) {
    put(e.key, e.value.toString());
  }
  return merged;
}
