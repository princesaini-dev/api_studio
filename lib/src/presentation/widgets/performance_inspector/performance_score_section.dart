import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceScoreSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceScoreSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final score = snapshot.performanceScore;
    final grade = snapshot.healthGrade;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.performanceHealth,
          icon: Icons.health_and_safety_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        _ScoreCard(score: score, grade: grade, theme: theme),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final PerformanceHealthGrade grade;
  final ApiInspectorThemeData theme;

  const _ScoreCard({
    required this.score,
    required this.grade,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _gradeData();

    return Container(
      padding: const EdgeInsets.all(Dimensions.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score.toString(),
                style: AppTextStyles.displayLarge.copyWith(color: color),
              ),
              Text(
                ' / 100',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: theme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.md,
              vertical: Dimensions.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            ),
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(color: color),
            ),
          ),
          const SizedBox(height: Dimensions.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: theme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: Dimensions.sm),
          Text(
            AppStrings.performanceScoreDisclaimer,
            style: AppTextStyles.labelSmall
                .copyWith(color: theme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  (Color, String) _gradeData() {
    switch (grade) {
      case PerformanceHealthGrade.excellent:
        return (AppColors.success, AppStrings.gradeExcellent);
      case PerformanceHealthGrade.good:
        return (AppColors.success, AppStrings.gradeGood);
      case PerformanceHealthGrade.fair:
        return (AppColors.warning, AppStrings.gradeFair);
      case PerformanceHealthGrade.poor:
        return (AppColors.error, AppStrings.gradePoor);
      case PerformanceHealthGrade.insufficientData:
        return (theme.textSecondaryColor, AppStrings.gradeInsufficientData);
    }
  }
}
