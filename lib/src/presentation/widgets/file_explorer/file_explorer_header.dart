import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class FileExplorerHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final ApiInspectorThemeData theme;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onBack;

  const FileExplorerHeader({
    super.key,
    required this.theme,
    required this.isLoading,
    required this.onRefresh,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(Dimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: Dimensions.lg,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: theme.textPrimaryColor, size: Dimensions.iconMd),
        tooltip: AppStrings.back,
        onPressed: onBack,
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: const Icon(Icons.folder_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: Dimensions.sm),
          Text(
            AppStrings.fileExplorer,
            style: AppTextStyles.headlineMedium
                .copyWith(color: theme.textPrimaryColor),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: theme.textSecondaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.refresh,
          onPressed: isLoading ? null : onRefresh,
        ),
        const SizedBox(width: Dimensions.xs),
      ],
    );
  }
}
