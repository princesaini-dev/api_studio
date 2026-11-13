import 'package:flutter/foundation.dart';
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

/// Bodies above this size are formatted on a background isolate so opening
/// a large response never blocks the UI thread.
const int _isolateThreshold = 32 * 1024;

/// Maximum characters laid out at once. Laying out a multi-megabyte
/// [SelectableText] takes seconds and a lot of memory, so larger bodies
/// show a preview with an explicit "show all" action (Copy always copies
/// the full body).
const int _previewChars = 64 * 1024;

({bool isValid, String formatted}) _format(String? raw) =>
    JsonFormatter.format(raw);

class _JsonViewerState extends State<JsonViewer> {
  String _formatted = '';
  bool _isJson = false;
  bool _ready = false;
  bool _showAll = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.raw;
    if (raw == null || raw.length < _isolateThreshold) {
      _apply(JsonFormatter.format(raw));
    } else {
      compute(_format, raw).then((r) {
        if (mounted) setState(() => _apply(r));
      }, onError: (Object _) {
        if (mounted) {
          setState(() => _apply((isValid: false, formatted: raw)));
        }
      });
    }
  }

  void _apply(({bool isValid, String formatted}) r) {
    _isJson = r.isValid;
    _formatted = r.formatted;
    _ready = true;
  }

  bool get _isClipped => !_showAll && _formatted.length > _previewChars;

  String get _visibleText =>
      _isClipped ? _formatted.substring(0, _previewChars) : _formatted;

  void _copy() async {
    if (!_ready || _formatted.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _formatted));
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJson
              ? 'JSON copied to clipboard'
              : 'Content copied to clipboard'),
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
          if (!_ready)
            const Padding(
              padding: EdgeInsets.all(Dimensions.lg),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _visibleText,
                    style: AppTextStyles.mono.copyWith(
                      color: theme.textPrimaryColor,
                      height: 1.65,
                    ),
                  ),
                ),
                if (_isClipped)
                  TextButton.icon(
                    onPressed: () => setState(() => _showAll = true),
                    icon: const Icon(Icons.unfold_more_rounded, size: 16),
                    label: Text(
                      'Showing ${_previewChars ~/ 1024} KB of '
                      '${(_formatted.length / 1024).toStringAsFixed(0)} KB '
                      '· Show all',
                    ),
                  ),
              ],
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
                      color: _copied
                          ? AppColors.success
                          : theme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _copied ? 'Copied' : 'Copy',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _copied
                            ? AppColors.success
                            : theme.textSecondaryColor,
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
