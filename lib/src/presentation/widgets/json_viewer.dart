import 'package:flutter/material.dart';
import '../../core/utils/json_formatter.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_text_styles.dart';

class JsonViewer extends StatefulWidget {
  final String? raw;

  const JsonViewer({super.key, this.raw});

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  late final String _formatted;
  late final bool _isJson;

  @override
  void initState() {
    super.initState();
    _isJson = JsonFormatter.isValidJson(widget.raw);
    _formatted =
        _isJson ? JsonFormatter.prettyPrint(widget.raw) : (widget.raw ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    if (widget.raw == null || widget.raw!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No content',
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.isDark
                ? const Color(0xFF0D1117)
                : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.borderColor),
          ),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              _formatted,
              style: AppTextStyles.mono.copyWith(
                color: theme.textPrimaryColor,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
