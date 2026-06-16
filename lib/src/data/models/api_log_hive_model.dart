import 'package:hive/hive.dart';
import '../../core/constants/hive_constants.dart';
import '../../domain/entities/api_log_entity.dart';

part 'api_log_hive_model.g.dart';

@HiveType(typeId: HiveConstants.apiLogTypeId)
class ApiLogHiveModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String url;

  @HiveField(2)
  late String method;

  @HiveField(3)
  late Map<String, dynamic> requestHeaders;

  @HiveField(4)
  late Map<String, dynamic> queryParams;

  @HiveField(5)
  String? requestBody;

  @HiveField(6)
  Map<String, dynamic>? formData;

  @HiveField(7)
  late bool isMultipart;

  @HiveField(8)
  late DateTime timestamp;

  @HiveField(9)
  int? durationMs;

  @HiveField(10)
  int? statusCode;

  @HiveField(11)
  String? responseBody;

  @HiveField(12)
  late Map<String, dynamic> responseHeaders;

  @HiveField(13)
  int? requestSizeBytes;

  @HiveField(14)
  int? responseSizeBytes;

  @HiveField(15)
  String? errorMessage;

  @HiveField(16)
  String? stackTrace;

  @HiveField(17)
  late String status;

  @HiveField(18)
  late bool isEdited;

  @HiveField(19)
  String? parentId;

  ApiLogHiveModel();

  factory ApiLogHiveModel.fromEntity(ApiLogEntity entity) {
    return ApiLogHiveModel()
      ..id = entity.id
      ..url = entity.url
      ..method = entity.method.name
      ..requestHeaders = entity.requestHeaders
      ..queryParams = entity.queryParams
      ..requestBody = entity.requestBody
      ..formData = entity.formData
      ..isMultipart = entity.isMultipart
      ..timestamp = entity.timestamp
      ..durationMs = entity.durationMs
      ..statusCode = entity.statusCode
      ..responseBody = entity.responseBody
      ..responseHeaders = entity.responseHeaders
      ..requestSizeBytes = entity.requestSizeBytes
      ..responseSizeBytes = entity.responseSizeBytes
      ..errorMessage = entity.errorMessage
      ..stackTrace = entity.stackTrace
      ..status = entity.status.name
      ..isEdited = entity.isEdited
      ..parentId = entity.parentId;
  }

  ApiLogEntity toEntity() {
    return ApiLogEntity(
      id: id,
      url: url,
      method: HttpMethod.values.firstWhere(
        (m) => m.name == method,
        orElse: () => HttpMethod.get,
      ),
      requestHeaders: requestHeaders,
      queryParams: queryParams,
      requestBody: requestBody,
      formData: formData,
      isMultipart: isMultipart,
      timestamp: timestamp,
      durationMs: durationMs,
      statusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      requestSizeBytes: requestSizeBytes,
      responseSizeBytes: responseSizeBytes,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      status: LogStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => LogStatus.error,
      ),
      isEdited: isEdited,
      parentId: parentId,
    );
  }
}
