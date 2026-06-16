import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/curl_generator.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CurlPreviewSheet extends StatefulWidget {
  final ApiLogEntity log;

  const CurlPreviewSheet({super.key, required this.log});

  static Future<void> show(BuildContext context, ApiLogEntity log) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Text('CURL Command', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimaryColor)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_rounded,
                      size: 16,
                      color: _copied ? AppColors.success : theme.primaryColor,
                    ),
                    label: Text(
                      _copied ? 'Copied!' : 'Copy',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _copied ? AppColors.success : theme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textSecondaryColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: SelectableText(
                      _curl,
                      style: AppTextStyles.mono.copyWith(color: theme.textPrimaryColor, height: 1.7),
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
