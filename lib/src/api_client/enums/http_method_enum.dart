/// HTTP methods supported by [ApiStudioClient].
enum ApiHttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  String get value => name.toUpperCase();
}
