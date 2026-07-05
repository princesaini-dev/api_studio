import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/curl_generator.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';

class CurlPreviewSheet extends StatefulWidget {
  final ApiLogEntity log;

  const CurlPreviewSheet({super.key, required this.log});

  static Future<void> show(BuildContext context, ApiLogEntity log) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusXl)),
      ),
      builder: (_) => CurlPreviewSheet(log: log),
    );
  }

  @override
  State<CurlPreviewSheet> createState() => _CurlPreviewSheetState();
}

class _CurlPreviewSheetState extends State<CurlPreviewSheet> {
  bool _copied = false;
  late final String _curl;

  @override
  void initState() {
    super.initState();
    _curl = CurlGenerator.generate(widget.log);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _curl));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusXl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: Dimensions.md),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusFull),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Dimensions.lg, Dimensions.md, Dimensions.sm, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                    child: const Icon(Icons.terminal_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: Dimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.curlCommand,
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: theme.textPrimaryColor)),
                        Text(AppStrings.curlDescription,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: theme.textSecondaryColor)),
                      ],
                    ),
                  ),
                  // Copy button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Container(
                            key: const ValueKey('copied'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.md,
                                vertical: Dimensions.xs + 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusMd),
                              border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded,
                                    size: 14, color: AppColors.success),
                                const SizedBox(width: Dimensions.xs),
                                Text(AppStrings.copied,
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: AppColors.success)),
                              ],
                            ),
                          )
                        : TextButton.icon(
                            key: const ValueKey('copy'),
                            onPressed: _copy,
                            icon: Icon(Icons.copy_rounded,
                                size: 14, color: theme.primaryColor),
                            label: Text(AppStrings.copy,
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: theme.primaryColor)),
                          ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: theme.textSecondaryColor,
                        size: Dimensions.iconMd),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: Dimensions.lg, color: theme.borderColor),
            // Code block
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                    Dimensions.lg, 0, Dimensions.lg, Dimensions.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.md),
                    decoration: BoxDecoration(
                      color: theme.isDark
                          ? AppColors.codeBlockDark
                          : AppColors.codeBlockLight,
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      border: Border.all(
                        color: theme.isDark
                            ? AppColors.codeBlockBorderDark
                            : AppColors.codeBlockBorderLight,
                      ),
                    ),
                    child: SelectableText(
                      _curl,
                      style: AppTextStyles.mono
                          .copyWith(color: theme.textPrimaryColor, height: 1.7),
                    ),
                  ),
                  // Large copy button at bottom
                  const SizedBox(height: Dimensions.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: _copied ? AppColors.success : theme.primaryColor,
                      ),
                      label: Text(
                        _copied ? AppStrings.copied : AppStrings.copyCurl,
                        style: AppTextStyles.labelLarge.copyWith(
                          color:
                              _copied ? AppColors.success : theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
