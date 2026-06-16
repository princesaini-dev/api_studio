import 'package:equatable/equatable.dart';

enum HttpMethod { get, post, put, patch, delete, head, options }

enum LogStatus { success, error, loading, cancelled }

class ApiLogEntity extends Equatable {
  final String id;
  final String url;
  final HttpMethod method;
  final Map<String, dynamic> requestHeaders;
  final Map<String, dynamic> queryParams;
  final String? requestBody;
  final Map<String, dynamic>? formData;
  final bool isMultipart;
  final DateTime timestamp;
  final int? durationMs;
  final int? statusCode;
  final String? responseBody;
  final Map<String, dynamic> responseHeaders;
  final int? requestSizeBytes;
  final int? responseSizeBytes;
  final String? errorMessage;
  final String? stackTrace;
  final LogStatus status;
  final bool isEdited;
  final String? parentId;

  const ApiLogEntity({
    required this.id,
    required this.url,
    required this.method,
    required this.requestHeaders,
    required this.queryParams,
    this.requestBody,
    this.formData,
    this.isMultipart = false,
    required this.timestamp,
    this.durationMs,
    this.statusCode,
    this.responseBody,
    required this.responseHeaders,
    this.requestSizeBytes,
    this.responseSizeBytes,
    this.errorMessage,
    this.stackTrace,
    required this.status,
    this.isEdited = false,
    this.parentId,
  });

  bool get isSuccess => status == LogStatus.success;
  bool get hasError => status == LogStatus.error;

  String get methodLabel => method.name.toUpperCase();

  String get shortUrl {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.path.isEmpty ? url : uri.path;
  }

  ApiLogEntity copyWith({
    String? id,
    String? url,
    HttpMethod? method,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? queryParams,
    String? requestBody,
    Map<String, dynamic>? formData,
    bool? isMultipart,
    DateTime? timestamp,
    int? durationMs,
    int? statusCode,
    String? responseBody,
    Map<String, dynamic>? responseHeaders,
    int? requestSizeBytes,
    int? responseSizeBytes,
    String? errorMessage,
    String? stackTrace,
    LogStatus? status,
    bool? isEdited,
    String? parentId,
  }) {
    return ApiLogEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      queryParams: queryParams ?? this.queryParams,
      requestBody: requestBody ?? this.requestBody,
      formData: formData ?? this.formData,
      isMultipart: isMultipart ?? this.isMultipart,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestSizeBytes: requestSizeBytes ?? this.requestSizeBytes,
      responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        method,
        requestHeaders,
        queryParams,
        requestBody,
        formData,
        isMultipart,
        timestamp,
        durationMs,
        statusCode,
        responseBody,
        responseHeaders,
        requestSizeBytes,
        responseSizeBytes,
        errorMessage,
        stackTrace,
        status,
        isEdited,
        parentId,
      ];
}
