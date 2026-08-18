import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_graph.dart';
import 'performance_section_header.dart';

class PerformanceFrameSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceFrameSection({
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
          title: AppStrings.framePerformance,
          icon: Icons.bolt_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        PerformanceGraph(
          dataPoints: snapshot.fpsHistory,
          maxValue: 120,
          warningThreshold: 45,
          criticalThreshold: 30,
          unit: 'fps',
          label: AppStrings.fpsGraph,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        PerformanceGraph(
          dataPoints: snapshot.frameTimeHistory,
          maxValue: 50,
          warningThreshold: 16,
          criticalThreshold: 33,
          unit: 'ms',
          label: AppStrings.frameTimeGraph,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        _DetailGrid(snapshot: snapshot, theme: theme),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _DetailGrid({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = snapshot.frameMetrics;
    final hasData = f.hasData;

    return Wrap(
      spacing: Dimensions.sm,
      runSpacing: Dimensions.sm,
      children: [
        _DetailChip(
          label: AppStrings.currentFps,
          value: hasData ? f.currentFps.toStringAsFixed(0) : '—',
          unit: 'fps',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.averageFps,
          value: hasData ? f.averageFps.toStringAsFixed(0) : '—',
          unit: 'fps',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.minFps,
          value: hasData ? f.minFps.toStringAsFixed(0) : '—',
          unit: 'fps',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.maxFps,
          value: hasData ? f.maxFps.toStringAsFixed(0) : '—',
          unit: 'fps',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.avgFrameTime,
          value: hasData ? f.averageFrameTimeMs.toStringAsFixed(1) : '—',
          unit: 'ms',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.slowFrames,
          value: hasData ? f.slowFrames.toString() : '—',
          unit: '',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.jankyFrames,
          value: hasData ? f.jankyFrames.toString() : '—',
          unit: '',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.jankPercentage,
          value: hasData ? f.jankRate.toStringAsFixed(1) : '—',
          unit: '%',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.uiThreadTime,
          value: hasData ? f.averageUiTimeMs.toStringAsFixed(1) : '—',
          unit: 'ms',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.rasterThreadTime,
          value: hasData ? f.averageRasterTimeMs.toStringAsFixed(1) : '—',
          unit: 'ms',
          theme: theme,
        ),
        _DetailChip(
          label: AppStrings.totalProcessingTime,
          value: hasData ? f.averageTotalProcessingMs.toStringAsFixed(1) : '—',
          unit: 'ms',
          theme: theme,
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final ApiInspectorThemeData theme;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.md,
        vertical: Dimensions.sm,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium
                .copyWith(color: theme.textSecondaryColor),
          ),
          const SizedBox(width: Dimensions.sm),
          Text(
            value,
            style: AppTextStyles.titleLarge
                .copyWith(color: theme.textPrimaryColor),
          ),
          if (unit.isNotEmpty)
            Text(
              ' $unit',
              style: AppTextStyles.labelSmall
                  .copyWith(color: theme.textSecondaryColor),
            ),
        ],
      ),
    );
  }
}
