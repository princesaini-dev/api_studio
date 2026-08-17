import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class ExternalOpenFailureDialog extends StatelessWidget {
  final ApiInspectorThemeData theme;
  final VoidCallback onDownload;

  const ExternalOpenFailureDialog({
    super.key,
    required this.theme,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusXl),
            ),
            child: const Icon(Icons.open_in_new_off_rounded,
                size: 28, color: AppColors.warning),
          ),
          const SizedBox(height: Dimensions.lg),
          Text(
            AppStrings.unableToOpenExternally,
            style: AppTextStyles.headlineSmall
                .copyWith(color: theme.textPrimaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.xs),
          Text(
            AppStrings.openExternallySubtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: theme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.cancel,
            style: AppTextStyles.titleMedium
                .copyWith(color: theme.textSecondaryColor),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onDownload();
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(AppStrings.download),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusMd),
            ),
          ),
        ),
      ],
    );
  }
}
