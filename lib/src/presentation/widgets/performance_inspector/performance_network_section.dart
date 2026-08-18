import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/network_performance.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceNetworkSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceNetworkSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final net = snapshot.networkPerformance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.networkPerformance,
          icon: Icons.cloud_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        if (!net.hasData)
          _NoNetworkData(theme: theme)
        else
          _NetworkDetails(net: net, theme: theme),
      ],
    );
  }
}

class _NoNetworkData extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const _NoNetworkData({required this.theme});

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
          AppStrings.noNetworkData,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NetworkDetails extends StatelessWidget {
  final NetworkPerformance net;
  final ApiInspectorThemeData theme;

  const _NetworkDetails({required this.net, required this.theme});

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
          _NetworkRow(
            label: AppStrings.totalRequests,
            value: net.totalRequests.toString(),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.successfulRequests,
            value: net.successfulRequests.toString(),
            theme: theme,
            valueColor: AppColors.success,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.failedRequests,
            value: net.failedRequests.toString(),
            theme: theme,
            valueColor: AppColors.error,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.timeouts,
            value: net.timeoutCount.toString(),
            theme: theme,
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.avgResponseTime,
            value: AppStrings.formatDuration(net.averageResponseTimeMs.round()),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.slowestRequest,
            value: net.slowestRequestMs != null
                ? AppStrings.formatDuration(net.slowestRequestMs)
                : AppStrings.labelNotAvailable,
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _NetworkRow(
            label: AppStrings.fastestRequest,
            value: net.fastestRequestMs != null
                ? AppStrings.formatDuration(net.fastestRequestMs)
                : AppStrings.labelNotAvailable,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  final String label;
  final String value;
  final ApiInspectorThemeData theme;
  final Color? valueColor;

  const _NetworkRow({
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
