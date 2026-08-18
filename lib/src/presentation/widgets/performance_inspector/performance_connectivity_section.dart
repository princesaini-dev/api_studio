import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/connectivity_performance.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceConnectivitySection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceConnectivitySection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final conn = snapshot.connectivityPerformance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.connectivityPerformance,
          icon: Icons.wifi_rounded,
          theme: theme,
        ),
        const SizedBox(height: Dimensions.sm),
        _ConnectivityCard(conn: conn, theme: theme),
      ],
    );
  }
}

class _ConnectivityCard extends StatelessWidget {
  final ConnectivityPerformance conn;
  final ApiInspectorThemeData theme;

  const _ConnectivityCard({required this.conn, required this.theme});

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
          _StatusRow(connected: conn.currentConnected, theme: theme),
          const SizedBox(height: Dimensions.sm),
          _ConnRow(
            label: AppStrings.connectivityChanges,
            value: conn.changeCount.toString(),
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _ConnRow(
            label: AppStrings.timeOffline,
            value: conn.timeOffline != null
                ? AppStrings.formatDuration(conn.timeOffline!.inSeconds)
                : AppStrings.labelNotAvailable,
            theme: theme,
          ),
          const SizedBox(height: Dimensions.xs),
          _ConnRow(
            label: AppStrings.failedRequestsOffline,
            value: conn.requestsFailedWhileOffline?.toString() ??
                AppStrings.labelNotAvailable,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool connected;
  final ApiInspectorThemeData theme;

  const _StatusRow({required this.connected, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Dimensions.sm),
        Text(
          connected ? AppStrings.connected : AppStrings.disconnected,
          style: AppTextStyles.titleMedium.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ConnRow extends StatelessWidget {
  final String label;
  final String value;
  final ApiInspectorThemeData theme;

  const _ConnRow({
    required this.label,
    required this.value,
    required this.theme,
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
          style:
              AppTextStyles.titleMedium.copyWith(color: theme.textPrimaryColor),
        ),
      ],
    );
  }
}
