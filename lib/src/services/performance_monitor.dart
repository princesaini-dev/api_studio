import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../data/datasources/performance_datasource.dart';
import '../domain/entities/connectivity_performance.dart';
import '../domain/entities/frame_metrics.dart';
import '../domain/entities/janky_frame.dart';
import '../domain/entities/memory_metrics.dart';
import '../domain/entities/network_performance.dart';
import '../domain/entities/performance_event.dart';
import '../domain/entities/performance_snapshot.dart';
import '../domain/entities/screen_performance.dart';
import '../domain/entities/startup_metrics.dart';

/// Central performance monitoring engine.
///
/// Collects frame timing data via [SchedulerBinding], polls memory usage
/// via the platform-aware [PerformanceDataSource], aggregates metrics
/// internally, and emits throttled [PerformanceSnapshot] updates through
/// a broadcast stream.
///
/// The monitor itself is designed to have minimal overhead:
/// - Frame data is aggregated, not stored per-frame.
/// - UI updates are throttled to a configurable interval.
/// - All collections are bounded.
/// - No disk writes or network requests.
class PerformanceMonitor {
  PerformanceMonitor._() {
    _dataSource = createPerformanceDataSource();
  }

  static final PerformanceMonitor instance = PerformanceMonitor._();

  final StreamController<PerformanceSnapshot> _controller =
      StreamController<PerformanceSnapshot>.broadcast();

  late final PerformanceDataSource _dataSource;

  // ── State ──────────────────────────────────────────────────────────

  bool _isMonitoring = false;
  bool _isRecording = false;
  DateTime? _sessionStart;
  DateTime? _recordingStart;
  Duration? get recordingDuration => _recordingStart != null
      ? DateTime.now().difference(_recordingStart!)
      : null;

  // Frame data
  int _totalFrames = 0;
  int _slowFrames = 0;
  int _jankyFrames = 0;
  double _sumFrameTime = 0;
  double _sumUiTime = 0;
  double _sumRasterTime = 0;
  double _minFps = double.infinity;
  double _maxFps = 0;
  double _lastFrameTimeMs = 0;
  double _lastUiTimeMs = 0;
  double _lastRasterTimeMs = 0;
  int _frameCounter = 0;

  // FPS tracking via frame count between ticks
  int _framesInInterval = 0;
  double _currentFps = 0;

  // Bounded history for graphs
  final List<double> _fpsHistory = [];
  final List<double> _frameTimeHistory = [];
  final List<JankyFrame> _recentJankyFrames = [];

  // Memory data
  final List<int> _memoryHistory = [];
  int? _peakMemory;
  int? _minMemory;
  int? _firstMemory;
  int? _lastMemory;

  // Timeline
  final List<PerformanceEvent> _timelineEvents = [];

  // Screen tracking
  final Map<String, _ScreenTracker> _screenTrackers = {};

  // Startup phases
  final List<StartupPhase> _startupPhases = [];
  DateTime? _appStart;

  // Connectivity
  final List<ConnectivityChangeRecord> _connectivityChanges = [];
  bool _currentConnectivity = true;

  // Timers
  Timer? _throttleTimer;
  Timer? _memoryTimer;

  static const Duration _throttleInterval = Duration(milliseconds: 500);
  static const Duration _memoryPollInterval = Duration(seconds: 2);
  static const int _maxGraphPoints = 120;
  static const int _maxTimelineEvents = 200;
  static const int _maxJankyFrames = 50;
  static const double _jankThresholdMs = 16.0;
  static const double _slowFrameThresholdMs = 25.0;

  // ── Public API ─────────────────────────────────────────────────────

  Stream<PerformanceSnapshot> get snapshotStream => _controller.stream;

  PerformanceSnapshot get currentSnapshot => _buildSnapshot();

  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;

  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _sessionStart ??= DateTime.now();
    _appStart ??= DateTime.now();

    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _memoryTimer = Timer.periodic(_memoryPollInterval, (_) => _pollMemory());
    _throttleTimer = Timer.periodic(_throttleInterval, (_) => _emitSnapshot());

    _addTimelineEvent(
      PerformanceEventType.appStarted,
      'Monitoring started',
      severity: PerformanceEventSeverity.info,
    );
    _emitSnapshot();
  }

  void stop() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _memoryTimer?.cancel();
    _memoryTimer = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _emitSnapshot();
  }

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _recordingStart = DateTime.now();
    _addTimelineEvent(
      PerformanceEventType.recordingStarted,
      'Recording started',
      severity: PerformanceEventSeverity.info,
    );
    _emitSnapshot();
  }

  void stopRecording() {
    if (!_isRecording) return;
    _isRecording = false;
    _addTimelineEvent(
      PerformanceEventType.recordingStopped,
      'Recording stopped',
      severity: PerformanceEventSeverity.info,
    );
    _emitSnapshot();
  }

  void clearSession() {
    _totalFrames = 0;
    _slowFrames = 0;
    _jankyFrames = 0;
    _sumFrameTime = 0;
    _sumUiTime = 0;
    _sumRasterTime = 0;
    _minFps = double.infinity;
    _maxFps = 0;
    _frameCounter = 0;
    _currentFps = 0;
    _fpsHistory.clear();
    _frameTimeHistory.clear();
    _recentJankyFrames.clear();
    _memoryHistory.clear();
    _peakMemory = null;
    _minMemory = null;
    _firstMemory = null;
    _lastMemory = null;
    _timelineEvents.clear();
    _screenTrackers.clear();
    _startupPhases.clear();
    _connectivityChanges.clear();
    _sessionStart = _isMonitoring ? DateTime.now() : null;
    _recordingStart = null;
    _emitSnapshot();
  }

  void markScreenStart(String name) {
    _screenTrackers[name] = _ScreenTracker(
      name: name,
      startTime: DateTime.now(),
      frameCount: 0,
      jankyCount: 0,
      sumFrameTime: 0,
    );
    _addTimelineEvent(
      PerformanceEventType.screenChanged,
      '$name opened',
      severity: PerformanceEventSeverity.info,
    );
  }

  void markScreenEnd(String name) {
    _screenTrackers[name]?.endTime = DateTime.now();
  }

  void recordStartupPhase(String name, {Duration? duration}) {
    _startupPhases.add(StartupPhase(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
    ));
  }

  void addCustomEvent(String description, {String? metricValue}) {
    _addTimelineEvent(
      PerformanceEventType.custom,
      description,
      metricValue: metricValue,
      severity: PerformanceEventSeverity.info,
    );
    _emitSnapshot();
  }

  void recordConnectivityChange(bool connected) {
    _currentConnectivity = connected;
    _connectivityChanges.add(ConnectivityChangeRecord(
      timestamp: DateTime.now(),
      connected: connected,
    ));
    _addTimelineEvent(
      PerformanceEventType.connectivityChanged,
      connected ? 'Connection restored' : 'Connection lost',
      severity: connected
          ? PerformanceEventSeverity.success
          : PerformanceEventSeverity.warning,
    );
    _emitSnapshot();
  }

  void recordApiRequest({
    required String url,
    required String method,
    int? statusCode,
    int? durationMs,
    bool isSuccess = true,
    bool isTimeout = false,
  }) {
    final type = isSuccess
        ? PerformanceEventType.apiRequest
        : PerformanceEventType.apiFailed;
    _addTimelineEvent(
      type,
      '$method ${_shortUrl(url)}${durationMs != null ? ' - ${durationMs}ms' : ''}',
      metricValue: durationMs?.toString(),
      severity: isSuccess
          ? PerformanceEventSeverity.success
          : (isTimeout
              ? PerformanceEventSeverity.warning
              : PerformanceEventSeverity.error),
    );
  }

  void dispose() {
    stop();
    if (!_controller.isClosed) _controller.close();
  }

  // ── Internal ───────────────────────────────────────────────────────

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _frameCounter++;
      _totalFrames++;
      _framesInInterval++;

      final frameTime = t.totalSpan.inMicroseconds / 1000.0;
      final uiTime = t.buildDuration.inMicroseconds / 1000.0;
      final rasterTime = t.rasterDuration.inMicroseconds / 1000.0;

      _sumFrameTime += frameTime;
      _sumUiTime += uiTime;
      _sumRasterTime += rasterTime;
      _lastFrameTimeMs = frameTime;
      _lastUiTimeMs = uiTime;
      _lastRasterTimeMs = rasterTime;

      if (frameTime > _slowFrameThresholdMs) {
        _slowFrames++;
      }

      final isJanky = frameTime > _jankThresholdMs * 2;
      if (isJanky) {
        _jankyFrames++;
        final severity = frameTime > 50
            ? FrameSeverity.critical
            : frameTime > 33
                ? FrameSeverity.warning
                : FrameSeverity.good;
        _recentJankyFrames.insert(
          0,
          JankyFrame(
            frameNumber: _frameCounter,
            durationMs: frameTime,
            uiTimeMs: uiTime,
            rasterTimeMs: rasterTime,
            severity: severity,
          ),
        );
        if (_recentJankyFrames.length > _maxJankyFrames) {
          _recentJankyFrames.removeLast();
        }
        _addTimelineEvent(
          PerformanceEventType.jankDetected,
          'Jank detected - ${frameTime.toStringAsFixed(1)} ms',
          metricValue: '${frameTime.toStringAsFixed(1)} ms',
          severity: PerformanceEventSeverity.warning,
        );
      }

      _frameTimeHistory.add(frameTime);
      if (_frameTimeHistory.length > _maxGraphPoints) {
        _frameTimeHistory.removeAt(0);
      }

      for (final tracker in _screenTrackers.values) {
        if (tracker.endTime != null) continue;
        tracker.frameCount++;
        tracker.sumFrameTime += frameTime;
        if (isJanky) tracker.jankyCount++;
      }
    }
  }

  void _pollMemory() {
    final mem = _dataSource.getCurrentMemoryUsageBytes();
    if (mem == null) return;

    _lastMemory = mem;
    _firstMemory ??= mem;
    _peakMemory =
        _peakMemory == null ? mem : (mem > _peakMemory! ? mem : _peakMemory);
    _minMemory =
        _minMemory == null ? mem : (mem < _minMemory! ? mem : _minMemory);

    _memoryHistory.add(mem);
    if (_memoryHistory.length > _maxGraphPoints) {
      _memoryHistory.removeAt(0);
    }

    for (final tracker in _screenTrackers.values) {
      if (tracker.endTime != null) continue;
      tracker.peakMemory = tracker.peakMemory == null
          ? mem
          : (mem > tracker.peakMemory! ? mem : tracker.peakMemory);
    }
  }

  void _addTimelineEvent(
    PerformanceEventType type,
    String description, {
    String? metricValue,
    PerformanceEventSeverity severity = PerformanceEventSeverity.info,
  }) {
    _timelineEvents.insert(
      0,
      PerformanceEvent(
        timestamp: DateTime.now(),
        type: type,
        description: description,
        metricValue: metricValue,
        severity: severity,
      ),
    );
    if (_timelineEvents.length > _maxTimelineEvents) {
      _timelineEvents.removeLast();
    }
  }

  void _emitSnapshot() {
    if (_controller.isClosed) return;

    // Calculate current FPS from frames since last emit
    if (_framesInInterval > 0 && _isMonitoring) {
      _currentFps =
          (_framesInInterval * 1000 / _throttleInterval.inMilliseconds)
              .clamp(0.0, 120.0);
      if (_currentFps < _minFps) _minFps = _currentFps;
      if (_currentFps > _maxFps) _maxFps = _currentFps;
      _fpsHistory.add(_currentFps);
      if (_fpsHistory.length > _maxGraphPoints) {
        _fpsHistory.removeAt(0);
      }
      _framesInInterval = 0;
    }

    _controller.add(_buildSnapshot());
  }

  PerformanceSnapshot _buildSnapshot() {
    final frameMetrics = _buildFrameMetrics();
    final memoryMetrics = _buildMemoryMetrics();
    final startupMetrics = _buildStartupMetrics();
    final screenPerformances = _buildScreenPerformances();
    final networkPerformance = _buildNetworkPerformance();
    final connectivityPerformance = _buildConnectivityPerformance();
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    final score = _calculateScore(frameMetrics, memoryMetrics);
    final grade = _scoreToGrade(score, frameMetrics);

    return PerformanceSnapshot(
      frameMetrics: frameMetrics,
      memoryMetrics: memoryMetrics,
      startupMetrics: startupMetrics,
      timelineEvents: List.unmodifiable(_timelineEvents),
      screenPerformances: screenPerformances,
      networkPerformance: networkPerformance,
      connectivityPerformance: connectivityPerformance,
      isMonitoring: _isMonitoring,
      isRecording: _isRecording,
      sessionDuration: sessionDuration,
      performanceScore: score,
      healthGrade: grade,
      fpsHistory: List.unmodifiable(_fpsHistory),
      frameTimeHistory: List.unmodifiable(_frameTimeHistory),
      memoryHistoryBytes: List.unmodifiable(_memoryHistory),
    );
  }

  FrameMetrics _buildFrameMetrics() {
    if (_totalFrames == 0) {
      return const FrameMetrics();
    }

    final avgFps = _fpsHistory.isNotEmpty
        ? (_fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length).toDouble()
        : 0.0;
    final minFps = (_minFps == double.infinity ? 0.0 : _minFps).toDouble();
    final jankRate = (_jankyFrames / _totalFrames) * 100.0;
    final avgFrameTime = _sumFrameTime / _totalFrames;
    final avgUi = _sumUiTime / _totalFrames;
    final avgRaster = _sumRasterTime / _totalFrames;

    final severity = jankRate > 10
        ? FrameSeverity.critical
        : jankRate > 5
            ? FrameSeverity.warning
            : FrameSeverity.good;

    return FrameMetrics(
      currentFps: _currentFps,
      averageFps: avgFps,
      minFps: minFps,
      maxFps: _maxFps,
      averageFrameTimeMs: avgFrameTime,
      totalFrames: _totalFrames,
      slowFrames: _slowFrames,
      jankyFrames: _jankyFrames,
      jankRate: jankRate,
      averageUiTimeMs: avgUi,
      averageRasterTimeMs: avgRaster,
      averageTotalProcessingMs: avgUi + avgRaster,
      lastFrameTimeMs: _lastFrameTimeMs,
      lastUiTimeMs: _lastUiTimeMs,
      lastRasterTimeMs: _lastRasterTimeMs,
      severity: severity,
    );
  }

  MemoryMetrics _buildMemoryMetrics() {
    if (!_dataSource.isMemoryAvailable || _lastMemory == null) {
      return const MemoryMetrics(isAvailable: false);
    }

    final growth = _lastMemory != null && _firstMemory != null
        ? _lastMemory! - _firstMemory!
        : null;

    MemoryTrend trend = MemoryTrend.unknown;
    if (_memoryHistory.length >= 5) {
      final recent = _memoryHistory.sublist(
        _memoryHistory.length - 5 > 0 ? _memoryHistory.length - 5 : 0,
      );
      final first = recent.first;
      final last = recent.last;
      final delta = last - first;
      final threshold = (first * 0.02).round();
      if (delta > threshold) {
        trend = MemoryTrend.growing;
      } else if (delta < -threshold) {
        trend = MemoryTrend.decreasing;
      } else {
        trend = MemoryTrend.stable;
      }
    }

    return MemoryMetrics(
      currentUsageBytes: _lastMemory,
      peakUsageBytes: _peakMemory,
      minUsageBytes: _minMemory,
      growthBytes: growth,
      trend: trend,
      sessionChangeBytes: growth,
      isAvailable: true,
    );
  }

  StartupMetrics _buildStartupMetrics() {
    if (_startupPhases.isEmpty) {
      return const StartupMetrics(isAvailable: false);
    }

    Duration? total;
    for (final p in _startupPhases) {
      if (p.duration != null) {
        total = (total ?? Duration.zero) + p.duration!;
      }
    }

    return StartupMetrics(
      phases: List.unmodifiable(_startupPhases),
      totalStartupDuration: total,
      isAvailable: true,
    );
  }

  List<ScreenPerformance> _buildScreenPerformances() {
    return _screenTrackers.entries.map((e) {
      final tracker = e.value;
      final duration = tracker.endTime != null
          ? tracker.endTime!.difference(tracker.startTime)
          : DateTime.now().difference(tracker.startTime);
      final avgFps = tracker.frameCount > 0
          ? tracker.sumFrameTime / tracker.frameCount
          : 0.0;
      final jankPct = tracker.frameCount > 0
          ? (tracker.jankyCount / tracker.frameCount) * 100
          : 0.0;

      final status = jankPct > 10
          ? ScreenPerformanceStatus.critical
          : jankPct > 5
              ? ScreenPerformanceStatus.warning
              : ScreenPerformanceStatus.good;

      return ScreenPerformance(
        screenName: tracker.name,
        loadTimeMs: tracker.loadTimeMs,
        averageFps: avgFps,
        jankyFrames: tracker.jankyCount,
        averageFrameTimeMs: tracker.frameCount > 0
            ? tracker.sumFrameTime / tracker.frameCount
            : 0,
        peakMemoryBytes: tracker.peakMemory,
        sessionDuration: duration,
        status: status,
      );
    }).toList();
  }

  NetworkPerformance _buildNetworkPerformance() {
    return const NetworkPerformance();
  }

  ConnectivityPerformance _buildConnectivityPerformance() {
    return ConnectivityPerformance(
      currentConnected: _currentConnectivity,
      changes: List.unmodifiable(_connectivityChanges),
      changeCount: _connectivityChanges.length,
    );
  }

  int _calculateScore(FrameMetrics frames, MemoryMetrics mem) {
    if (!frames.hasData) return 0;

    int score = 100;

    // FPS penalty
    if (frames.averageFps < 60) {
      score -= (60 - frames.averageFps).clamp(0, 30).toInt();
    }

    // Jank penalty
    if (frames.jankRate > 5) {
      score -= (frames.jankRate * 2).clamp(0, 30).toInt();
    }

    // Slow frames penalty
    if (frames.totalFrames > 0) {
      final slowPct = (frames.slowFrames / frames.totalFrames) * 100;
      if (slowPct > 5) {
        score -= slowPct.clamp(0, 15).toInt();
      }
    }

    // Memory growth penalty
    if (mem.isAvailable &&
        mem.growthBytes != null &&
        _firstMemory != null &&
        _firstMemory! > 0) {
      final growthPct = (mem.growthBytes! / _firstMemory!) * 100;
      if (growthPct > 20) {
        score -= growthPct.clamp(0, 15).toInt();
      }
    }

    return score.clamp(0, 100);
  }

  PerformanceHealthGrade _scoreToGrade(
    int score,
    FrameMetrics frames,
  ) {
    if (!frames.hasData) return PerformanceHealthGrade.insufficientData;
    if (score >= 85) return PerformanceHealthGrade.excellent;
    if (score >= 70) return PerformanceHealthGrade.good;
    if (score >= 50) return PerformanceHealthGrade.fair;
    return PerformanceHealthGrade.poor;
  }

  String _shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.path.isEmpty ? url : uri.path;
  }
}

class _ScreenTracker {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  int frameCount;
  int jankyCount;
  double sumFrameTime;
  int? loadTimeMs;
  int? peakMemory;

  _ScreenTracker({
    required this.name,
    required this.startTime,
    required this.frameCount,
    required this.jankyCount,
    required this.sumFrameTime,
  });
}
