import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class EditedBadge extends StatelessWidget {
  const EditedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.editedBadge.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.editedBadge.withValues(alpha: 0.5)),
      ),
      child: Text(
        'EDITED',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.editedBadge,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
