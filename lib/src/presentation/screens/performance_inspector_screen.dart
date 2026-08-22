import 'dart:async';

import 'package:flutter/material.dart';

import '../../api_client/core/api_studio_performance_uploader.dart';
import '../../domain/entities/performance_snapshot.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/dimensions.dart';
import '../states/performance_state.dart';
import '../controllers/performance_controller.dart';
import '../widgets/performance_inspector/performance_connectivity_section.dart';
import '../widgets/performance_inspector/performance_frame_section.dart';
import '../widgets/performance_inspector/performance_inspector_header.dart';
import '../widgets/performance_inspector/performance_jank_section.dart';
import '../widgets/performance_inspector/performance_memory_section.dart';
import '../widgets/performance_inspector/performance_network_section.dart';
import '../widgets/performance_inspector/performance_overview.dart';
import '../widgets/performance_inspector/performance_score_section.dart';
import '../widgets/performance_inspector/performance_screen_section.dart';
import '../widgets/performance_inspector/performance_startup_section.dart';
import '../widgets/performance_inspector/performance_timeline_section.dart';

class PerformanceInspectorScreen extends StatefulWidget {
  const PerformanceInspectorScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const PerformanceInspectorScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<PerformanceInspectorScreen> createState() =>
      _PerformanceInspectorScreenState();
}

class _PerformanceInspectorScreenState
    extends State<PerformanceInspectorScreen> {
  late final PerformanceController _controller;

  @override
  void initState() {
    super.initState();
    unawaited(PerformanceTelemetryUploader.uploadNow());
    _controller = DiService.createPerformanceController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceInspectorView(controller: _controller);
  }
}

class PerformanceInspectorView extends StatelessWidget {
  final PerformanceController controller;
  const PerformanceInspectorView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(Dimensions.appBarHeight),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final state = controller.state;
            return PerformanceInspectorHeader(
              theme: theme,
              isMonitoring: state.snapshot.isMonitoring,
              isRecording: state.snapshot.isRecording,
              onToggleMonitoring: () => _onToggleMonitoring(context, state),
              onClearSession: () => controller.clearSession(),
              onBack: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _PerformanceContent(
            snapshot: controller.state.snapshot,
            theme: theme,
          );
        },
      ),
    );
  }

  void _onToggleMonitoring(BuildContext context, PerformanceState state) {
    if (state.snapshot.isMonitoring) {
      controller.stopMonitoring();
    } else {
      controller.startMonitoring();
    }
  }
}

class _PerformanceContent extends StatelessWidget {
  final PerformanceSnapshot snapshot;
  final ApiInspectorThemeData theme;

  const _PerformanceContent({
    required this.snapshot,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerformanceOverview(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceFrameSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceJankSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceMemorySection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceStartupSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceScreenSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceNetworkSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceConnectivitySection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceTimelineSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xl),
          PerformanceScoreSection(snapshot: snapshot, theme: theme),
          const SizedBox(height: Dimensions.xxl),
        ],
      ),
    );
  }
}
