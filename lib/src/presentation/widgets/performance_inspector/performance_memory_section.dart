import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/memory_metrics.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_graph.dart';
import 'performance_section_header.dart';

class PerformanceMemorySection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceMemorySection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final mem = snapshot.memoryMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.memory,
          icon: Icons.memory_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        if (!mem.isAvailable)
          _UnavailableCard(theme: theme)
        else ...[
          _MemoryGraphCard(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.sm),
          _MemoryDetails(mem: mem, theme: theme),
        ],
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const _UnavailableCard({required this.theme});

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
          AppStrings.memoryNotAvailable,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MemoryGraphCard extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _MemoryGraphCard({required this.snapshot, required this.theme});

  @override
  Widget build(BuildContext context) {
    final memHistory = snapshot.memoryHistoryBytes;
    final dataPoints = memHistory.map((b) => b.toDouble()).toList();
    final maxVal = dataPoints.isNotEmpty
        ? dataPoints.reduce((a, b) => a > b ? a : b) * 1.1
        : 100.0;

    return PerformanceGraph(
      dataPoints: dataPoints,
      maxValue: maxVal,
      warningThreshold: maxVal * 0.8,
      criticalThreshold: maxVal * 0.95,
      unit: 'B',
      label: AppStrings.memoryGraph,
      theme: theme,
    );
  }
}

class _MemoryDetails extends StatelessWidget {
  final MemoryMetrics mem;
  final ApiInspectorThemeData theme;

  const _MemoryDetails({required this.mem, required this.theme});

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
        children: [
          _MemoryRow(
            label: AppStrings.currentMemory,
            value: AppStrings.formatBytes(mem.currentUsageBytes),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _MemoryRow(
            label: AppStrings.peakMemory,
            value: AppStrings.formatBytes(mem.peakUsageBytes),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _MemoryRow(
            label: AppStrings.minMemory,
            value: AppStrings.formatBytes(mem.minUsageBytes),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _MemoryRow(
            label: AppStrings.memoryGrowth,
            value: _formatGrowth(mem.growthBytes),
            theme: theme,
            valueColor: _trendColor(mem.trend),
          ),
          const SizedBox(height: Dimensions.xs),
          _MemoryRow(
            label: AppStrings.memoryTrend,
            value: _trendLabel(mem.trend),
            theme: theme,
            valueColor: _trendColor(mem.trend),
          ),
          const SizedBox(height: Dimensions.xs),
          _MemoryRow(
            label: AppStrings.sessionMemoryChange,
            value: _formatGrowth(mem.sessionChangeBytes),
            theme: theme,
          ),
        ],
      ),
    );
  }

  String _formatGrowth(int? bytes) {
    if (bytes == null) return AppStrings.labelNotAvailable;
    if (bytes >= 0) return '+${AppStrings.formatBytes(bytes)}';
    return AppStrings.formatBytes(bytes.abs());
  }

  String _trendLabel(MemoryTrend trend) {
    switch (trend) {
      case MemoryTrend.stable:
        return AppStrings.memoryTrendStable;
      case MemoryTrend.growing:
        return AppStrings.memoryTrendGrowing;
      case MemoryTrend.decreasing:
        return AppStrings.memoryTrendDecreasing;
      case MemoryTrend.unknown:
        return AppStrings.memoryTrendUnknown;
    }
  }

  Color _trendColor(MemoryTrend trend) {
    switch (trend) {
      case MemoryTrend.stable:
        return AppColors.success;
      case MemoryTrend.growing:
        return AppColors.warning;
      case MemoryTrend.decreasing:
        return AppColors.success;
      case MemoryTrend.unknown:
        return theme.textSecondaryColor;
    }
  }
}

class _MemoryRow extends StatelessWidget {
  final String label;
  final String value;
  final ApiInspectorThemeData theme;
  final Color? valueColor;

  const _MemoryRow({
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
          style: AppTextStyles.titleMedium
              .copyWith(color: valueColor ?? theme.textPrimaryColor),
        ),
      ],
    );
  }
}
