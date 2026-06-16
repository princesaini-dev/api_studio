import 'package:flutter/material.dart';
import 'api_inspector_theme_data.dart';

class ApiInspectorTheme extends InheritedWidget {
  final ApiInspectorThemeData data;

  const ApiInspectorTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static ApiInspectorThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<ApiInspectorTheme>();
    if (theme != null) return theme.data;
    final brightness = Theme.of(context).brightness;
    return ApiInspectorThemeData.fromBrightness(brightness);
  }

  static ApiInspectorThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ApiInspectorTheme>()?.data;
  }

  @override
  bool updateShouldNotify(ApiInspectorTheme oldWidget) => data != oldWidget.data;
}
