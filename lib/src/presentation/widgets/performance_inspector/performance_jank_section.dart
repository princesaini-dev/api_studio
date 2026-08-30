import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/frame_metrics.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceJankSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceJankSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.jankDetection,
          icon: Icons.warning_amber_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        _JankSummary(snapshot: snapshot, theme: theme),
        const SizedBox(height: Dimensions.sm),
        _RecentJankyFrames(snapshot: snapshot, theme: theme),
      ],
    );
  }
}

class _JankSummary extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _JankSummary({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = snapshot.frameMetrics;

    return Container(
      padding: const EdgeInsets.all(Dimensions.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: AppStrings.totalFrames,
            value: f.totalFrames.toString(),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _SummaryRow(
            label: AppStrings.jankyFrames,
            value: f.jankyFrames.toString(),
            theme: theme,
            valueColor: _severityColor(f.severity),
          ),
          const SizedBox(height: Dimensions.xs),
          _SummaryRow(
            label: AppStrings.jankRate,
            value: f.hasData ? '${f.jankRate.toStringAsFixed(1)}%' : '—',
            theme: theme,
            valueColor: _severityColor(f.severity),
          ),
        ],
      ),
    );
  }

  Color _severityColor(FrameSeverity severity) {
    switch (severity) {
      case FrameSeverity.good:
        return AppColors.success;
      case FrameSeverity.warning:
        return AppColors.warning;
      case FrameSeverity.critical:
        return AppColors.error;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ApiInspectorThemeData theme;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
        ),
        Text(
          value,
          style: AppTextStyles.titleLarge
              .copyWith(color: valueColor ?? theme.textPrimaryColor),
        ),
      ],
    );
  }
}

class _RecentJankyFrames extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _RecentJankyFrames({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = snapshot.frameMetrics;

    if (!f.hasData || f.jankyFrames == 0) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.lg),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        child: Center(
          child: Text(
            AppStrings.noJankDetected,
            style: AppTextStyles.bodyMedium
                .copyWith(color: theme.textSecondaryColor),
          ),
        ),
      );
    }

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
          Text(
            AppStrings.recentSlowFrames,
            style: AppTextStyles.titleMedium
                .copyWith(color: theme.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.sm),
          _JankFrameChart(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.sm),
          _WorstFrameInfo(snapshot: snapshot, theme: theme),
        ],
      ),
    );
  }
}

class _JankFrameChart extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _JankFrameChart({required this.snapshot, required this.theme});

  static const double _chartHeight = 160;
  static const double _barWidth = 10;
  static const double _barSpacing = 4;

  @override
  Widget build(BuildContext context) {
    final frames = snapshot.frameTimeHistory;
    final maxDuration = frames.fold<double>(
      16,
      (maximum, duration) => duration > maximum ? duration : maximum,
    );

    return SizedBox(
      width: double.infinity,
      height: _chartHeight,
      child: ClipRect(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          reverse: true,
          itemCount: frames.length,
          separatorBuilder: (_, __) => const SizedBox(width: _barSpacing),
          itemBuilder: (context, index) {
            final duration = frames[frames.length - index - 1];
            final height =
                (duration / maxDuration * (_chartHeight - Dimensions.md))
                    .clamp(2.0, _chartHeight - Dimensions.md);
            final color = duration > 50
                ? AppColors.error
                : duration > 33
                    ? AppColors.warning
                    : theme.primaryColor;

            return Align(
              alignment: Alignment.bottomCenter,
              child: Tooltip(
                message: AppStrings.frameDuration(duration),
                child: SizedBox(
                  width: _barWidth,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorstFrameInfo extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _WorstFrameInfo({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = snapshot.frameMetrics;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.md,
        vertical: Dimensions.sm,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.worstFrame,
            style: AppTextStyles.labelMedium
                .copyWith(color: theme.textSecondaryColor),
          ),
          const SizedBox(height: Dimensions.xs),
          Text(
            AppStrings.frameDuration(f.lastFrameTimeMs),
            style:
                AppTextStyles.bodyLarge.copyWith(color: theme.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.xs),
          Row(
            children: [
              Text(
                'UI: ${f.lastUiTimeMs.toStringAsFixed(1)} ms',
                style: AppTextStyles.monoSmall
                    .copyWith(color: theme.textSecondaryColor),
              ),
              const SizedBox(width: Dimensions.md),
              Text(
                'Raster: ${f.lastRasterTimeMs.toStringAsFixed(1)} ms',
                style: AppTextStyles.monoSmall
                    .copyWith(color: theme.textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
