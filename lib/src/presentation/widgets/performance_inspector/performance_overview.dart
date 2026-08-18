import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/performance_snapshot.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/dimensions.dart';
import 'performance_metric_card.dart';

class PerformanceOverview extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const PerformanceOverview({
    super.key,
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final frames = snapshot.frameMetrics;
    final mem = snapshot.memoryMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.fps,
            value: frames.hasData ? frames.currentFps.toStringAsFixed(0) : '—',
            unit: 'fps',
            status: _fpsStatus(frames.currentFps),
            icon: Icons.speed_rounded,
            theme: theme,
            tooltip: AppStrings.fpsTooltip,
          ),
          PerformanceMetricCard(
            label: AppStrings.averageFps,
            value: frames.hasData ? frames.averageFps.toStringAsFixed(0) : '—',
            unit: 'fps',
            status: _fpsStatus(frames.averageFps),
            icon: Icons.trending_up_rounded,
            theme: theme,
          ),
        ]),
        const SizedBox(height: Dimensions.sm),
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.minFps,
            value: frames.hasData ? frames.minFps.toStringAsFixed(0) : '—',
            unit: 'fps',
            status: _fpsStatus(frames.minFps),
            icon: Icons.south_rounded,
            theme: theme,
          ),
          PerformanceMetricCard(
            label: AppStrings.frameTime,
            value: frames.hasData
                ? frames.lastFrameTimeMs.toStringAsFixed(1)
                : '—',
            unit: 'ms',
            status: _frameTimeStatus(frames.lastFrameTimeMs),
            icon: Icons.timer_rounded,
            theme: theme,
          ),
        ]),
        const SizedBox(height: Dimensions.sm),
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.jankyFrames,
            value: frames.hasData ? frames.jankyFrames.toString() : '—',
            unit: '',
            status: _jankStatus(frames.jankRate),
            icon: Icons.warning_amber_rounded,
            theme: theme,
          ),
          PerformanceMetricCard(
            label: AppStrings.jankRate,
            value: frames.hasData ? frames.jankRate.toStringAsFixed(1) : '—',
            unit: '%',
            status: _jankStatus(frames.jankRate),
            icon: Icons.percent_rounded,
            theme: theme,
          ),
        ]),
        const SizedBox(height: Dimensions.sm),
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.uiTime,
            value:
                frames.hasData ? frames.lastUiTimeMs.toStringAsFixed(1) : '—',
            unit: 'ms',
            status: _frameTimeStatus(frames.lastUiTimeMs),
            icon: Icons.memory_rounded,
            theme: theme,
          ),
          PerformanceMetricCard(
            label: AppStrings.rasterTime,
            value: frames.hasData
                ? frames.lastRasterTimeMs.toStringAsFixed(1)
                : '—',
            unit: 'ms',
            status: _frameTimeStatus(frames.lastRasterTimeMs),
            icon: Icons.layers_rounded,
            theme: theme,
          ),
        ]),
        const SizedBox(height: Dimensions.sm),
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.memoryUsage,
            value: mem.hasData
                ? AppStrings.formatBytes(mem.currentUsageBytes)
                : '—',
            unit: '',
            status: mem.isAvailable
                ? MetricStatus.neutral
                : MetricStatus.unavailable,
            icon: Icons.memory_rounded,
            theme: theme,
          ),
          PerformanceMetricCard(
            label: AppStrings.peakMemory,
            value:
                mem.hasData ? AppStrings.formatBytes(mem.peakUsageBytes) : '—',
            unit: '',
            status: mem.isAvailable
                ? MetricStatus.neutral
                : MetricStatus.unavailable,
            icon: Icons.vertical_align_top_rounded,
            theme: theme,
          ),
        ]),
        const SizedBox(height: Dimensions.sm),
        _buildRow([
          PerformanceMetricCard(
            label: AppStrings.appStartupTime,
            value: snapshot.startupMetrics.hasData
                ? AppStrings.formatDuration(snapshot
                    .startupMetrics.totalStartupDuration?.inMilliseconds)
                : '—',
            unit: '',
            status: snapshot.startupMetrics.isAvailable
                ? MetricStatus.neutral
                : MetricStatus.unavailable,
            icon: Icons.rocket_launch_rounded,
            theme: theme,
          ),
          PerformanceMetricCard(
            label: AppStrings.sessionDuration,
            value: _formatDuration(snapshot.sessionDuration),
            unit: '',
            status: MetricStatus.neutral,
            icon: Icons.schedule_rounded,
            theme: theme,
          ),
        ]),
      ],
    );
  }

  Widget _buildRow(List<Widget> cards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: Dimensions.sm),
          Expanded(child: cards[1]),
        ],
      ),
    );
  }

  MetricStatus _fpsStatus(double fps) {
    if (fps == 0) return MetricStatus.neutral;
    if (fps >= 55) return MetricStatus.good;
    if (fps >= 40) return MetricStatus.warning;
    return MetricStatus.critical;
  }

  MetricStatus _frameTimeStatus(double ms) {
    if (ms == 0) return MetricStatus.neutral;
    if (ms <= 16) return MetricStatus.good;
    if (ms <= 33) return MetricStatus.warning;
    return MetricStatus.critical;
  }

  MetricStatus _jankStatus(double rate) {
    if (rate == 0) return MetricStatus.good;
    if (rate <= 5) return MetricStatus.good;
    if (rate <= 10) return MetricStatus.warning;
    return MetricStatus.critical;
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}
