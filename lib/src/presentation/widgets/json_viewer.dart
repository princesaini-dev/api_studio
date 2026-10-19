import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/json_formatter.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';

class JsonViewer extends StatefulWidget {
  final String? raw;

  const JsonViewer({super.key, this.raw});

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  late final String _formatted;
  late final bool _isJson;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final result = JsonFormatter.format(widget.raw);
    _isJson = result.isValid;
    _formatted = result.formatted;
  }

  void _copy() async {
    if (_formatted.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _formatted));
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJson ? 'JSON copied to clipboard' : 'Content copied to clipboard'),
          duration: const Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    if (widget.raw == null || widget.raw!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Dimensions.lg),
        child: Text(
          'No content',
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:
            theme.isDark ? AppColors.codeBlockDark : AppColors.codeBlockLight,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(
          color: theme.isDark
              ? AppColors.codeBlockBorderDark
              : AppColors.codeBlockBorderLight,
        ),
      ),
      padding: const EdgeInsets.all(Dimensions.md),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              _formatted,
              style: AppTextStyles.mono.copyWith(
                color: theme.textPrimaryColor,
                height: 1.65,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              onTap: _copy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (theme.isDark ? Colors.black54 : Colors.white70),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  border: Border.all(
                    color: theme.isDark
                        ? AppColors.codeBlockBorderDark
                        : AppColors.codeBlockBorderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 14,
                      color: _copied ? AppColors.success : theme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _copied ? 'Copied' : 'Copy',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _copied ? AppColors.success : theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
