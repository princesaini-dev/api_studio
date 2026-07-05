import 'dart:typed_data';

/// Represents a single file part in a multipart/form-data request.
class ApiMultipartFile {
  final String field;
  final String filename;
  final Uint8List bytes;
  final String contentType;

  const ApiMultipartFile({
    required this.field,
    required this.filename,
    required this.bytes,
    this.contentType = 'application/octet-stream',
  });
}
