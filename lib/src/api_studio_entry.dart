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
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
  }) async {
    if (theme != null) _themeData = theme;
    await DiService.init(
      maxStoredLogs: maxStoredLogs,
      requestTimeout: requestTimeout,
      enableConnectivityStream: enableConnectivityStream,
      enableFailedApiStream: enableFailedApiStream,
    );
  }

  static ApiInspectorInterceptor get interceptor => DiService.interceptor;

  static Future<bool> isInternetConnected() => DiService.isInternetAvailable;

  static Stream<bool> get internetConnectivityStream =>
      DiService.internetConnectivityStream;

  static int get failedApiCount => DiService.failedApiCount;

  static Stream<int> get failedApiCountStream =>
      DiService.failedApiCountStream;

  static void show(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ApiInspectorTheme(
          data: effectiveTheme,
          child: const InspectorListScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
