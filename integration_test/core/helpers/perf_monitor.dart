import 'package:flutter/scheduler.dart';

class PerfMonitorReport {
  const PerfMonitorReport({
    required this.frameCount,
    required this.jankyFrames,
    required this.severeJankyFrames,
    required this.averageFrameMs,
    required this.worstFrameMs,
  });

  final int frameCount;
  final int jankyFrames;
  final int severeJankyFrames;
  final double averageFrameMs;
  final double worstFrameMs;

  double get jankRatio => frameCount == 0 ? 0 : jankyFrames / frameCount;
  double get severeJankRatio =>
      frameCount == 0 ? 0 : severeJankyFrames / frameCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'frameCount': frameCount,
        'jankyFrames': jankyFrames,
        'severeJankyFrames': severeJankyFrames,
        'averageFrameMs': averageFrameMs,
        'worstFrameMs': worstFrameMs,
        'jankRatio': jankRatio,
        'severeJankRatio': severeJankRatio,
      };
}

class PerfMonitor {
  final List<FrameTiming> _timings = <FrameTiming>[];
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  PerfMonitorReport stop() {
    if (_started) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _started = false;
    }

    if (_timings.isEmpty) {
      return const PerfMonitorReport(
        frameCount: 0,
        jankyFrames: 0,
        severeJankyFrames: 0,
        averageFrameMs: 0,
        worstFrameMs: 0,
      );
    }

    var totalMs = 0.0;
    var worstMs = 0.0;
    var janky = 0;
    var severe = 0;

    for (final timing in _timings) {
      final frameMs = timing.totalSpan.inMicroseconds / 1000.0;
      totalMs += frameMs;
      if (frameMs > worstMs) worstMs = frameMs;
      if (frameMs > 16.0) janky += 1;
      if (frameMs > 32.0) severe += 1;
    }

    return PerfMonitorReport(
      frameCount: _timings.length,
      jankyFrames: janky,
      severeJankyFrames: severe,
      averageFrameMs: totalMs / _timings.length,
      worstFrameMs: worstMs,
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
  }
}
