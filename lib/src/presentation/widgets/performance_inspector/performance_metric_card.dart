import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

enum MetricStatus { good, warning, critical, unavailable, neutral }

class PerformanceMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final MetricStatus status;
  final IconData icon;
  final String? tooltip;
  final ApiInspectorThemeData theme;
  final bool animateValue;
  final String? previousValue;

  const PerformanceMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.theme,
    this.tooltip,
    this.animateValue = false,
    this.previousValue,
  });

  Color _statusColor() {
    switch (status) {
      case MetricStatus.good:
        return AppColors.success;
      case MetricStatus.warning:
        return AppColors.warning;
      case MetricStatus.critical:
        return AppColors.error;
      case MetricStatus.unavailable:
        return AppColors.statusCancelled;
      case MetricStatus.neutral:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        padding: const EdgeInsets.all(Dimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: Dimensions.iconSm, color: _statusColor()),
                const SizedBox(width: Dimensions.xs),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: theme.textSecondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tooltip != null)
                  Tooltip(
                    message: tooltip!,
                    child: Icon(Icons.info_outline_rounded,
                        size: 12, color: theme.textSecondaryColor),
                  ),
              ],
            ),
            const SizedBox(height: Dimensions.sm),
            if (status == MetricStatus.unavailable)
              Text(
                AppStrings.notAvailableOnPlatform,
                style: AppTextStyles.labelSmall
                    .copyWith(color: theme.textSecondaryColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (animateValue && previousValue != null)
                    _AnimatedMetricValue(
                      value: value,
                      previousValue: previousValue!,
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: theme.textPrimaryColor),
                    )
                  else
                    Text(
                      value,
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: theme.textPrimaryColor),
                    ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: Dimensions.xs),
                    Text(
                      unit,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: theme.textSecondaryColor),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: Dimensions.xs),
            _StatusIndicator(status: status, color: _statusColor()),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final MetricStatus status;
  final Color color;

  const _StatusIndicator({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Dimensions.xs),
        Text(
          _statusLabel(),
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }

  String _statusLabel() {
    switch (status) {
      case MetricStatus.good:
        return AppStrings.good;
      case MetricStatus.warning:
        return AppStrings.warning;
      case MetricStatus.critical:
        return AppStrings.critical;
      case MetricStatus.unavailable:
        return AppStrings.unavailable;
      case MetricStatus.neutral:
        return AppStrings.active;
    }
  }
}

class _AnimatedMetricValue extends StatefulWidget {
  final String value;
  final String previousValue;
  final TextStyle style;

  const _AnimatedMetricValue({
    required this.value,
    required this.previousValue,
    required this.style,
  });

  @override
  State<_AnimatedMetricValue> createState() => _AnimatedMetricValueState();
}

class _AnimatedMetricValueState extends State<_AnimatedMetricValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedMetricValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Text(widget.value, style: widget.style),
        ),
      ),
    );
  }
}
