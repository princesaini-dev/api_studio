import 'package:hive_ce/hive.dart';
import '../../core/constants/hive_constants.dart';
import '../../domain/entities/api_log_entity.dart';

/// Hive representation of an [ApiLogEntity].
///
/// The binary layout (type id 0, fields 0–19) is unchanged from API Studio
/// 1.0.x so existing boxes remain readable after the `hive` → `hive_ce`
/// migration. Field 20 (`isTruncated`) was added in 1.1.0.
class ApiLogHiveModel extends HiveObject {
  late String id;
  late String url;
  late String method;
  late Map<String, dynamic> requestHeaders;
  late Map<String, dynamic> queryParams;
  String? requestBody;
  Map<String, dynamic>? formData;
  late bool isMultipart;
  late DateTime timestamp;
  int? durationMs;
  int? statusCode;
  String? responseBody;
  late Map<String, dynamic> responseHeaders;
  int? requestSizeBytes;
  int? responseSizeBytes;
  String? errorMessage;
  String? stackTrace;
  late String status;
  late bool isEdited;
  String? parentId;
  bool isTruncated = false;

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
      ..parentId = entity.parentId
      ..isTruncated = entity.isTruncated;
  }

  /// Approximate number of bytes this log's variable-size fields occupy.
  int get approximateSizeBytes =>
      (requestBody?.length ?? 0) +
      (responseBody?.length ?? 0) +
      (stackTrace?.length ?? 0) +
      url.length;

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
      isTruncated: isTruncated,
    );
  }
}

/// Hand-written, defensive [TypeAdapter] for [ApiLogHiveModel].
///
/// Unlike a generated adapter it never throws on missing or mistyped fields
/// (e.g. records written by an older or newer version) — it substitutes
/// safe defaults instead, so one bad record cannot crash the host app.
class ApiLogHiveModelAdapter extends TypeAdapter<ApiLogHiveModel> {
  @override
  final int typeId = HiveConstants.apiLogTypeId;

  static const int _fieldCount = 21;

  @override
  ApiLogHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiLogHiveModel()
      ..id = _str(f[0]) ?? ''
      ..url = _str(f[1]) ?? ''
      ..method = _str(f[2]) ?? HttpMethod.get.name
      ..requestHeaders = _map(f[3]) ?? <String, dynamic>{}
      ..queryParams = _map(f[4]) ?? <String, dynamic>{}
      ..requestBody = _str(f[5])
      ..formData = _map(f[6])
      ..isMultipart = f[7] is bool ? f[7] as bool : false
      ..timestamp = f[8] is DateTime
          ? f[8] as DateTime
          : DateTime.fromMillisecondsSinceEpoch(0)
      ..durationMs = f[9] is int ? f[9] as int : null
      ..statusCode = f[10] is int ? f[10] as int : null
      ..responseBody = _str(f[11])
      ..responseHeaders = _map(f[12]) ?? <String, dynamic>{}
      ..requestSizeBytes = f[13] is int ? f[13] as int : null
      ..responseSizeBytes = f[14] is int ? f[14] as int : null
      ..errorMessage = _str(f[15])
      ..stackTrace = _str(f[16])
      ..status = _str(f[17]) ?? LogStatus.error.name
      ..isEdited = f[18] is bool ? f[18] as bool : false
      ..parentId = _str(f[19])
      ..isTruncated = f[20] is bool ? f[20] as bool : false;
  }

  @override
  void write(BinaryWriter writer, ApiLogHiveModel obj) {
    writer
      ..writeByte(_fieldCount)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.requestHeaders)
      ..writeByte(4)
      ..write(obj.queryParams)
      ..writeByte(5)
      ..write(obj.requestBody)
      ..writeByte(6)
      ..write(obj.formData)
      ..writeByte(7)
      ..write(obj.isMultipart)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.durationMs)
      ..writeByte(10)
      ..write(obj.statusCode)
      ..writeByte(11)
      ..write(obj.responseBody)
      ..writeByte(12)
      ..write(obj.responseHeaders)
      ..writeByte(13)
      ..write(obj.requestSizeBytes)
      ..writeByte(14)
      ..write(obj.responseSizeBytes)
      ..writeByte(15)
      ..write(obj.errorMessage)
      ..writeByte(16)
      ..write(obj.stackTrace)
      ..writeByte(17)
      ..write(obj.status)
      ..writeByte(18)
      ..write(obj.isEdited)
      ..writeByte(19)
      ..write(obj.parentId)
      ..writeByte(20)
      ..write(obj.isTruncated);
  }

  static String? _str(dynamic v) => v is String ? v : v?.toString();

  static Map<String, dynamic>? _map(dynamic v) {
    if (v is! Map) return null;
    return {for (final e in v.entries) e.key.toString(): e.value};
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiLogHiveModelAdapter && typeId == other.typeId;
}
