// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_log_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiLogHiveModelAdapter extends TypeAdapter<ApiLogHiveModel> {
  @override
  final int typeId = 0;

  @override
  ApiLogHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiLogHiveModel()
      ..id = fields[0] as String
      ..url = fields[1] as String
      ..method = fields[2] as String
      ..requestHeaders = (fields[3] as Map).cast<String, dynamic>()
      ..queryParams = (fields[4] as Map).cast<String, dynamic>()
      ..requestBody = fields[5] as String?
      ..formData = (fields[6] as Map?)?.cast<String, dynamic>()
      ..isMultipart = fields[7] as bool
      ..timestamp = fields[8] as DateTime
      ..durationMs = fields[9] as int?
      ..statusCode = fields[10] as int?
      ..responseBody = fields[11] as String?
      ..responseHeaders = (fields[12] as Map).cast<String, dynamic>()
      ..requestSizeBytes = fields[13] as int?
      ..responseSizeBytes = fields[14] as int?
      ..errorMessage = fields[15] as String?
      ..stackTrace = fields[16] as String?
      ..status = fields[17] as String
      ..isEdited = fields[18] as bool
      ..parentId = fields[19] as String?;
  }

  @override
  void write(BinaryWriter writer, ApiLogHiveModel obj) {
    writer
      ..writeByte(20)
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
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiLogHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
