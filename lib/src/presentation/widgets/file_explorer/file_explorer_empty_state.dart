import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class FileExplorerEmptyState extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const FileExplorerEmptyState({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusXl),
              ),
              child: const Icon(Icons.folder_open_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: Dimensions.lg),
            Text(
              AppStrings.emptyFolder,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: theme.textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.xs),
            Text(
              AppStrings.emptyFolderSubtitle,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
