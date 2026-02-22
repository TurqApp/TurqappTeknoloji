import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final _performance = FirebasePerformance.instance;

  /// Bir işlemi trace ile izle
  static Future<T> traceOperation<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();

    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute(
          'error',
          e.toString().length > 100
              ? e.toString().substring(0, 100)
              : e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Açılış süresini ölç
  static Future<void> traceAppStartup(
      Future<void> Function() startupWork) async {
    final trace = _performance.newTrace('app_startup');
    await trace.start();

    final stopwatch = Stopwatch()..start();
    try {
      await startupWork();
      stopwatch.stop();
      trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
      trace.putAttribute('status', 'success');
      if (kDebugMode) {
        debugPrint('⚡ App startup: ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      stopwatch.stop();
      trace.putAttribute('status', 'error');
    } finally {
      await trace.stop();
    }
  }

  /// Feed yükleme süresini ölç
  static Future<T> traceFeedLoad<T>(
    Future<T> Function() loadOperation, {
    int? postCount,
    String? feedMode,
  }) async {
    final trace = _performance.newTrace('feed_load');
    await trace.start();

    try {
      final result = await loadOperation();
      if (postCount != null) {
        trace.setMetric('post_count', postCount);
      }
      if (feedMode != null && feedMode.isNotEmpty) {
        trace.putAttribute('feed_mode', feedMode);
      }
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Custom HTTP trace
  static HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}
