import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/performance_snapshot.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/dimensions.dart';
import '../controllers/performance_controller.dart';
import '../widgets/performance_inspector/performance_connectivity_section.dart';
import '../widgets/performance_inspector/performance_frame_section.dart';
import '../widgets/performance_inspector/performance_inspector_header.dart';
import '../widgets/performance_inspector/performance_jank_section.dart';
import '../widgets/performance_inspector/performance_memory_section.dart';
import '../widgets/performance_inspector/performance_overview.dart';
import '../widgets/performance_inspector/performance_score_section.dart';

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
  bool _startedMonitoring = false;

  @override
  void initState() {
    super.initState();
    _controller = DiService.createPerformanceController();
  }

  @override
  void dispose() {
    if (_startedMonitoring && _controller.state.snapshot.isMonitoring) {
      _controller.stopMonitoring();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceInspectorView(
      controller: _controller,
      onMonitoringStarted: () => _startedMonitoring = true,
      onMonitoringStopped: () => _startedMonitoring = false,
    );
  }
}

class PerformanceInspectorView extends StatelessWidget {
  final PerformanceController controller;
  final VoidCallback onMonitoringStarted;
  final VoidCallback onMonitoringStopped;

  const PerformanceInspectorView({
    super.key,
    required this.controller,
    this.onMonitoringStarted = _noop,
    this.onMonitoringStopped = _noop,
  });

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(Dimensions.appBarHeight),
        child: ValueListenableBuilder<PerformanceSnapshot>(
          valueListenable: controller.headerSnapshot,
          builder: (context, snapshot, _) {
            return PerformanceInspectorHeader(
              theme: theme,
              isMonitoring: snapshot.isMonitoring,
              isRecording: snapshot.isRecording,
              onToggleMonitoring: () {
                if (snapshot.isMonitoring) {
                  controller.stopMonitoring();
                  onMonitoringStopped();
                } else {
                  controller.startMonitoring();
                  onMonitoringStarted();
                }
              },
              onClearSession: controller.clearSession,
              onBack: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
      body: _PerformanceContent(controller: controller, theme: theme),
    );
  }
}

class _PerformanceContent extends StatelessWidget {
  final PerformanceController controller;
  final ApiInspectorThemeData theme;

  const _PerformanceContent({
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SnapshotSection(
            listenable: controller.overviewSnapshot,
            builder: (snapshot) =>
                PerformanceOverview(snapshot: snapshot, theme: theme),
          ),
          const SizedBox(height: Dimensions.xl),
          _SnapshotSection(
            listenable: controller.frameSnapshot,
            builder: (snapshot) => Column(
              children: [
                PerformanceFrameSection(snapshot: snapshot, theme: theme),
                const SizedBox(height: Dimensions.xl),
                PerformanceJankSection(snapshot: snapshot, theme: theme),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.xl),
          _SnapshotSection(
            listenable: controller.memorySnapshot,
            builder: (snapshot) =>
                PerformanceMemorySection(snapshot: snapshot, theme: theme),
          ),
          const SizedBox(height: Dimensions.xl),
          _SnapshotSection(
            listenable: controller.connectivitySnapshot,
            builder: (snapshot) => PerformanceConnectivitySection(
              snapshot: snapshot,
              theme: theme,
            ),
          ),
          const SizedBox(height: Dimensions.xl),
          _SnapshotSection(
            listenable: controller.scoreSnapshot,
            builder: (snapshot) =>
                PerformanceScoreSection(snapshot: snapshot, theme: theme),
          ),
          const SizedBox(height: Dimensions.xxl),
        ],
      ),
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  final ValueListenable<PerformanceSnapshot> listenable;
  final Widget Function(PerformanceSnapshot snapshot) builder;

  const _SnapshotSection({
    required this.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<PerformanceSnapshot>(
        valueListenable: listenable,
        builder: (context, snapshot, _) => builder(snapshot),
      ),
    );
  }
}
