import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../domain/entities/startup_metrics.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceStartupSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceStartupSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final startup = snapshot.startupMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.startupPerformance,
          icon: Icons.rocket_launch_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        if (!startup.isAvailable)
          _StartupUnavailable(theme: theme)
        else
          _StartupTimeline(startup: startup, theme: theme),
      ],
    );
  }
}

class _StartupUnavailable extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const _StartupUnavailable({required this.theme});

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
          AppStrings.startupNotAvailable,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StartupTimeline extends StatelessWidget {
  final StartupMetrics startup;
  final ApiInspectorThemeData theme;

  const _StartupTimeline({required this.startup, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (startup.totalStartupDuration != null)
            _StartupTotalRow(startup: startup, theme: theme),
          if (startup.totalStartupDuration != null)
            const SizedBox(height: Dimensions.md),
          ...startup.phases.map((phase) => _StartupPhaseRow(
                phase: phase,
                theme: theme,
                maxDurationMs:
                    startup.totalStartupDuration?.inMilliseconds.toDouble() ??
                        1.0,
              )),
        ],
      ),
    );
  }
}

class _StartupTotalRow extends StatelessWidget {
  final StartupMetrics startup;
  final ApiInspectorThemeData theme;

  const _StartupTotalRow({required this.startup, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.totalStartupDuration,
          style:
              AppTextStyles.titleMedium.copyWith(color: theme.textPrimaryColor),
        ),
        Text(
          AppStrings.formatDuration(
              startup.totalStartupDuration?.inMilliseconds),
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _StartupPhaseRow extends StatelessWidget {
  final StartupPhase phase;
  final ApiInspectorThemeData theme;
  final double maxDurationMs;

  const _StartupPhaseRow({
    required this.phase,
    required this.theme,
    required this.maxDurationMs,
  });

  @override
  Widget build(BuildContext context) {
    final durationMs = phase.duration?.inMilliseconds.toDouble() ?? 0;
    final progress =
        maxDurationMs > 0 ? (durationMs / maxDurationMs).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phase.name,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.textSecondaryColor),
              ),
              Text(
                phase.hasData
                    ? AppStrings.formatDuration(phase.duration?.inMilliseconds)
                    : AppStrings.labelNotAvailable,
                style: AppTextStyles.monoSmall
                    .copyWith(color: theme.textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.borderColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
