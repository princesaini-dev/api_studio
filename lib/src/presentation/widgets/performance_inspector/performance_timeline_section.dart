import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_event.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';
import 'performance_section_header.dart';

class PerformanceTimelineSection extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceTimelineSection({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final events = snapshot.timelineEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceSectionHeader(
          title: AppStrings.performanceTimeline,
          icon: Icons.timeline_rounded,
          theme: theme,
          trailing: Text(
            '${events.length}',
            style: AppTextStyles.labelMedium
                .copyWith(color: theme.textSecondaryColor),
          ),
        ),
        const SizedBox(height: Dimensions.sm),
        if (events.isEmpty)
          _NoEventsCard(theme: theme)
        else
          _TimelineList(events: events, theme: theme),
      ],
    );
  }
}

class _NoEventsCard extends StatelessWidget {
  final ApiInspectorThemeData theme;

  const _NoEventsCard({required this.theme});

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
          AppStrings.noTimelineEvents,
          style: AppTextStyles.bodyMedium
              .copyWith(color: theme.textSecondaryColor),
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  final List<PerformanceEvent> events;
  final ApiInspectorThemeData theme;

  const _TimelineList({required this.events, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.borderColor,
        ),
        itemBuilder: (context, index) {
          return _TimelineEventRow(event: events[index], theme: theme);
        },
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  final PerformanceEvent event;
  final ApiInspectorThemeData theme;

  const _TimelineEventRow({required this.event, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _eventVisual();

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: Dimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.textPrimaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatTime(event.timestamp),
                        style: AppTextStyles.monoSmall
                            .copyWith(color: theme.textSecondaryColor),
                      ),
                      if (event.metricValue != null) ...[
                        const SizedBox(width: Dimensions.sm),
                        Text(
                          event.metricValue!,
                          style: AppTextStyles.monoSmall.copyWith(color: color),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _eventVisual() {
    switch (event.type) {
      case PerformanceEventType.appStarted:
        return (Icons.play_arrow_rounded, AppColors.primary);
      case PerformanceEventType.screenChanged:
        return (Icons.phone_android_rounded, AppColors.info);
      case PerformanceEventType.apiRequest:
        return (Icons.cloud_done_rounded, AppColors.success);
      case PerformanceEventType.apiFailed:
        return (Icons.cloud_off_rounded, AppColors.error);
      case PerformanceEventType.jankDetected:
        return (Icons.warning_amber_rounded, AppColors.warning);
      case PerformanceEventType.memoryUpdate:
        return (Icons.memory_rounded, AppColors.info);
      case PerformanceEventType.connectivityChanged:
        return (Icons.wifi_rounded, AppColors.warning);
      case PerformanceEventType.recordingStarted:
        return (Icons.fiber_manual_record_rounded, AppColors.error);
      case PerformanceEventType.recordingStopped:
        return (Icons.stop_rounded, AppColors.statusCancelled);
      case PerformanceEventType.custom:
        return (Icons.event_rounded, AppColors.primary);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
