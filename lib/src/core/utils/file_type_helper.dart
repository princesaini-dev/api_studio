import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class FileTypeHelper {
  FileTypeHelper._();

  static IconData iconForExtension(String ext) {
    switch (ext) {
      case 'json':
        return Icons.data_object_rounded;
      case 'txt':
      case 'md':
        return Icons.text_snippet_outlined;
      case 'db':
      case 'sqlite':
      case 'sqlite3':
        return Icons.storage_rounded;
      case 'log':
        return Icons.article_outlined;
      case 'yaml':
      case 'yml':
        return Icons.settings_outlined;
      case 'xml':
      case 'svg':
      case 'html':
        return Icons.code_rounded;
      case 'csv':
        return Icons.table_chart_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'zip':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_outlined;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.movie_outlined;
      case 'mp3':
      case 'wav':
        return Icons.music_note_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  static Color colorForExtension(String ext, Color fallback) {
    switch (ext) {
      case 'json':
        return AppColors.info;
      case 'db':
      case 'sqlite':
      case 'sqlite3':
        return AppColors.warning;
      case 'log':
        return AppColors.success;
      case 'yaml':
      case 'yml':
        return AppColors.methodPatch;
      default:
        return fallback;
    }
  }
}
