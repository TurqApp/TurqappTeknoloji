// 📁 lib/Services/user_analytics_service.dart
// 📊 Analytics service for user behavior tracking
// Integrates with CurrentUserService

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_summary_models.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class UserAnalyticsService {
  static UserAnalyticsService? _instance;
  static UserAnalyticsService? maybeFind() => _instance;

  static UserAnalyticsService ensure() =>
      maybeFind() ?? (_instance = UserAnalyticsService._internal());

  static UserAnalyticsService get instance => ensure();
  UserAnalyticsService._internal();

  final _userService = CurrentUserService.instance;
  bool _writesDisabledByPermission = false;

  bool get _canWrite {
    // Debug log temizliği için analytics write'larını kapat.
    if (kDebugMode) return false;
    return !_writesDisabledByPermission;
  }

  /// Track cache hit/miss
  Future<void> trackCachePerformance({
    required bool cacheHit,
    required int loadTimeMs,
  }) async {
    try {
      if (!_canWrite) return;
      if (!_userService.isLoggedIn) return;

      await FirebaseFirestore.instance
          .collection('Analytics')
          .doc('CachePerformance')
          .collection(_userService.userId)
          .add({
        'cacheHit': cacheHit,
        'loadTimeMs': loadTimeMs,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'device': 'mobile', // TODO: Get from device info
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _writesDisabledByPermission = true;
      }
    } catch (_) {
      // Silent fail for analytics
    }
  }

  /// Track user session
  Future<void> trackSession({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      if (!_canWrite) return;
      if (!_userService.isLoggedIn) return;

      final durationMinutes = endTime.difference(startTime).inMinutes;

      await FirebaseFirestore.instance
          .collection('Analytics')
          .doc('UserSessions')
          .collection(_userService.userId)
          .add({
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'durationMinutes': durationMinutes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _writesDisabledByPermission = true;
      }
    } catch (_) {
      // Silent fail for analytics
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    try {
      if (!_canWrite) return;
      if (!_userService.isLoggedIn) return;

      await FirebaseFirestore.instance
          .collection('Analytics')
          .doc('FeatureUsage')
          .collection(_userService.userId)
          .add({
        'feature': featureName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _writesDisabledByPermission = true;
      }
    } catch (_) {
      // Silent fail for analytics
    }
  }

  Future<void> trackRuntimeHealthSummary({
    required String surface,
    CacheFirstSurfaceSummary? cacheFirst,
    RenderDiffSurfaceSummary? renderDiff,
    PlaybackWindowSurfaceSummary? playbackWindow,
    Map<String, dynamic>? extra,
  }) async {
    try {
      if (!_canWrite) return;
      if (!_userService.isLoggedIn) return;

      await FirebaseFirestore.instance
          .collection('Analytics')
          .doc('RuntimeHealth')
          .collection(_userService.userId)
          .add({
        'surface': surface,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        if (cacheFirst != null) ...{
          'cacheEventCount': cacheFirst.eventCount,
          'cacheLocalHitCount': cacheFirst.localHitCount,
          'cacheWarmHitCount': cacheFirst.warmHitCount,
          'cacheLiveSuccessCount': cacheFirst.liveSuccessCount,
          'cacheLiveFailCount': cacheFirst.liveFailCount,
          'cachePreservedPreviousCount': cacheFirst.preservedPreviousCount,
          'cacheLocalHitRatio': cacheFirst.localHitRatio,
        },
        if (renderDiff != null) ...{
          'renderEventCount': renderDiff.eventCount,
          'renderPatchEventCount': renderDiff.patchEventCount,
          'renderZeroDiffCount': renderDiff.zeroDiffCount,
          'renderAverageOperations': renderDiff.averageOperations,
          'renderMaxOperations': renderDiff.maxOperations,
        },
        if (playbackWindow != null) ...{
          'playbackEventCount': playbackWindow.eventCount,
          'playbackAverageVisibleCount': playbackWindow.averageVisibleCount,
          'playbackAverageHotCount': playbackWindow.averageHotCount,
          'playbackActiveLostCount': playbackWindow.activeLostCount,
          'playbackMaxAttachedPlayers': playbackWindow.maxAttachedPlayers,
        },
        ...?extra,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _writesDisabledByPermission = true;
      }
    } catch (_) {
      // Silent fail for analytics
    }
  }
}
