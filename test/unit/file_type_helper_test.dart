import 'package:flutter_test/flutter_test.dart';
import 'package:api_studio/src/core/utils/file_type_helper.dart';
import 'package:flutter/material.dart';

void main() {
  group('FileTypeHelper.iconForExtension', () {
    test('returns correct icon for json', () {
      expect(
          FileTypeHelper.iconForExtension('json'), Icons.data_object_rounded);
    });

    test('returns correct icon for txt', () {
      expect(
          FileTypeHelper.iconForExtension('txt'), Icons.text_snippet_outlined);
    });

    test('returns correct icon for db', () {
      expect(FileTypeHelper.iconForExtension('db'), Icons.storage_rounded);
    });

    test('returns correct icon for png', () {
      expect(FileTypeHelper.iconForExtension('png'), Icons.image_outlined);
    });

    test('returns correct icon for pdf', () {
      expect(FileTypeHelper.iconForExtension('pdf'),
          Icons.picture_as_pdf_outlined);
    });

    test('returns default icon for unknown extension', () {
      expect(
          FileTypeHelper.iconForExtension('xyz'), Icons.description_outlined);
    });

    test('returns default icon for empty extension', () {
      expect(FileTypeHelper.iconForExtension(''), Icons.description_outlined);
    });
  });

  group('FileTypeHelper.colorForExtension', () {
    test('returns AppColors.info for json', () {
      expect(FileTypeHelper.colorForExtension('json', const Color(0xFF000000)),
          isA<Color>());
    });

    test('returns fallback for unknown extension', () {
      const fallback = Color(0xFF123456);
      expect(FileTypeHelper.colorForExtension('xyz', fallback), fallback);
    });

    test('returns fallback for empty extension', () {
      const fallback = Color(0xFF789ABC);
      expect(FileTypeHelper.colorForExtension('', fallback), fallback);
    });
  });
}
