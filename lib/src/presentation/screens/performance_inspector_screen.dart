import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api_client/core/api_studio_performance_uploader.dart';
import '../../domain/entities/performance_snapshot.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/dimensions.dart';
import '../blocs/performance/performance_bloc.dart';
import '../blocs/performance/performance_event.dart';
import '../blocs/performance/performance_state.dart';
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
  @override
  void initState() {
    super.initState();
    unawaited(PerformanceTelemetryUploader.uploadNow());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiService.createPerformanceBloc(),
      child: const PerformanceInspectorView(),
    );
  }
}

class PerformanceInspectorView extends StatelessWidget {
  const PerformanceInspectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(Dimensions.appBarHeight),
        child: BlocBuilder<PerformanceBloc, PerformanceState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.snapshot.isMonitoring != curr.snapshot.isMonitoring ||
              prev.snapshot.isRecording != curr.snapshot.isRecording,
          builder: (context, state) {
            return PerformanceInspectorHeader(
              theme: theme,
              isMonitoring: state.snapshot.isMonitoring,
              isRecording: state.snapshot.isRecording,
              onToggleMonitoring: () => _onToggleMonitoring(context, state),
              onClearSession: () => context
                  .read<PerformanceBloc>()
                  .add(const PerformanceClearSessionEvent()),
              onBack: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
      body: BlocBuilder<PerformanceBloc, PerformanceState>(
        buildWhen: (prev, curr) => prev.snapshot != curr.snapshot,
        builder: (context, state) {
          return _PerformanceContent(
            snapshot: state.snapshot,
            theme: theme,
          );
        },
      ),
    );
  }

  void _onToggleMonitoring(BuildContext context, PerformanceState state) {
    final bloc = context.read<PerformanceBloc>();
    if (state.snapshot.isMonitoring) {
      bloc.add(const PerformanceStopMonitoringEvent());
    } else {
      bloc.add(const PerformanceStartMonitoringEvent());
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
