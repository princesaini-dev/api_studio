import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class PerformanceInspectorHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final ApiInspectorThemeData theme;
  final bool isMonitoring;
  final bool isRecording;
  final VoidCallback onToggleMonitoring;
  final VoidCallback onClearSession;
  final VoidCallback onBack;

  const PerformanceInspectorHeader({
    super.key,
    required this.theme,
    required this.isMonitoring,
    required this.isRecording,
    required this.onToggleMonitoring,
    required this.onClearSession,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(Dimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: Dimensions.lg,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: theme.textPrimaryColor, size: Dimensions.iconMd),
        tooltip: AppStrings.back,
        onPressed: onBack,
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: const Icon(Icons.speed_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: Dimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.performanceInspector,
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: theme.textPrimaryColor),
                ),
                Text(
                  isRecording
                      ? AppStrings.recording
                      : isMonitoring
                          ? AppStrings.monitoringActive
                          : AppStrings.monitoringInactive,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: theme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isRecording)
          const _RecordingIndicator()
        else
          IconButton(
            icon: Icon(
              isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: isMonitoring ? AppColors.error : AppColors.success,
              size: Dimensions.iconMd,
            ),
            tooltip: isMonitoring
                ? AppStrings.stopMonitoring
                : AppStrings.startMonitoring,
            onPressed: onToggleMonitoring,
          ),
        IconButton(
          icon: Icon(Icons.cleaning_services_rounded,
              color: theme.textSecondaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.clearSession,
          onPressed: onClearSession,
        ),
        const SizedBox(width: Dimensions.xs),
      ],
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.sm),
      child: _PulsingDot(),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 0.4 + (_controller.value * 0.6),
            child: child,
          );
        },
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
