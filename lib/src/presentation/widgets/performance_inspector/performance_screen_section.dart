import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../domain/entities/screen_performance.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceScreenSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceScreenSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final screens = snapshot.screenPerformances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.screenPerformance,
          icon: Icons.phone_android_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        if (screens.isEmpty)
          _NoScreensCard(theme: theme)
        else
          _ScreenList(screens: screens, theme: theme),
      ],
    );
  }
}

class _NoScreensCard extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const _NoScreensCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: Center(
        child: Text(
          AppStrings.noScreensTracked,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ScreenList extends StatelessWidget {
  final List<ScreenPerformance> screens;
  final ApiInspectorThemeData theme;

  const _ScreenList({required this.screens, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: screens.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimensions.xs),
      itemBuilder: (context, index) {
        return _ScreenCard(screen: screens[index], theme: theme);
      },
    );
  }
}

class _ScreenCard extends StatelessWidget {
  final ScreenPerformance screen;
  final ApiInspectorThemeData theme;

  const _ScreenCard({required this.screen, required this.theme});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.md),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screen.screenName,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: theme.textPrimaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.xs),
                  Row(
                    children: [
                      Text(
                        '${screen.averageFps.toStringAsFixed(0)} FPS',
                        style: AppTextStyles.monoSmall
                            .copyWith(color: theme.textSecondaryColor),
                      ),
                      const SizedBox(width: Dimensions.md),
                      Text(
                        '${screen.jankyFrames} ${AppStrings.jank}',
                        style: AppTextStyles.monoSmall
                            .copyWith(color: theme.textSecondaryColor),
                      ),
                      if (screen.loadTimeMs != null) ...[
                        const SizedBox(width: Dimensions.md),
                        Text(
                          AppStrings.formatDuration(screen.loadTimeMs),
                          style: AppTextStyles.monoSmall
                              .copyWith(color: theme.textSecondaryColor),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _ScreenStatusBadge(status: screen.status, theme: theme),
          ],
        ),
      ),
    );
  }
}

class _ScreenStatusBadge extends StatelessWidget {
  final ScreenPerformanceStatus status;
  final ApiInspectorThemeData theme;

  const _ScreenStatusBadge({required this.status, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusData();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.sm,
        vertical: Dimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  (Color, String) _statusData() {
    switch (status) {
      case ScreenPerformanceStatus.good:
        return (AppColors.success, AppStrings.good);
      case ScreenPerformanceStatus.warning:
        return (AppColors.warning, AppStrings.warning);
      case ScreenPerformanceStatus.critical:
        return (AppColors.error, AppStrings.critical);
    }
  }
}
