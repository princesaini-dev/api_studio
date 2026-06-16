import 'package:flutter/material.dart';
import 'services/di_service.dart';
import 'presentation/screens/inspector_list_screen.dart';
import 'theme/api_inspector_theme.dart';
import 'theme/api_inspector_theme_data.dart';
import 'data/interceptor/api_inspector_interceptor.dart';

class ApiStudio {
  ApiStudio._();

  static ApiInspectorThemeData _themeData = const ApiInspectorThemeData();

  static Future<void> init({
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
  }) async {
    if (theme != null) _themeData = theme;
    await DiService.init(
      maxStoredLogs: maxStoredLogs,
      requestTimeout: requestTimeout,
    );
  }

  static ApiInspectorInterceptor get interceptor => DiService.interceptor;

  static void show(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApiInspectorTheme(
          data: effectiveTheme,
          child: const InspectorListScreen(),
        ),
      ),
    );
  }
}
