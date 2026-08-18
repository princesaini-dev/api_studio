import 'package:flutter/material.dart';

import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class PerformanceSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ApiInspectorThemeData theme;
  final Widget? trailing;

  const PerformanceSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.theme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: Dimensions.iconSm, color: AppColors.primary),
        const SizedBox(width: Dimensions.sm),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineSmall
                .copyWith(color: theme.textPrimaryColor),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
