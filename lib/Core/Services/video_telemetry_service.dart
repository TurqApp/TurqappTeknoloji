import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class VideoSessionMetrics {
  final String videoId;
  final String videoUrl;
  final DateTime sessionStart;
  DateTime? firstFrameAt;
  int rebufferCount = 0;
  int totalRebufferMs = 0;
  double maxPositionReached = 0.0;
  double videoDuration = 0.0;
  int seekCount = 0;
  String? errorMessage;
  bool completed = false;
  bool isAudible = false;
  bool hasStableFocus = false;
  DateTime? _lastBufferStart;

  VideoSessionMetrics({required this.videoId, required this.videoUrl})
      : sessionStart = DateTime.now();

  int get ttffMs => firstFrameAt != null
      ? firstFrameAt!.difference(sessionStart).inMilliseconds
      : -1;

  double get watchTimeSeconds =>
      DateTime.now().difference(sessionStart).inMilliseconds / 1000.0;

  double get completionRate => videoDuration > 0
      ? (maxPositionReached / videoDuration).clamp(0.0, 1.0)
      : 0.0;

  double get rebufferRatio {
    final total = watchTimeSeconds * 1000;
    return total > 0 ? (totalRebufferMs / total).clamp(0.0, 1.0) : 0.0;
  }

  void markFirstFrame() {
    firstFrameAt ??= DateTime.now();
  }

  void onBufferingStart() {
    _lastBufferStart = DateTime.now();
    rebufferCount++;
  }

  void onBufferingEnd() {
    if (_lastBufferStart != null) {
      totalRebufferMs +=
          DateTime.now().difference(_lastBufferStart!).inMilliseconds;
      _lastBufferStart = null;
    }
  }

  void onPositionUpdate(double position, double duration) {
    if (position > maxPositionReached) maxPositionReached = position;
    if (duration > 0) videoDuration = duration;
  }

  void onSeek() => seekCount++;

  void onCompleted() => completed = true;

  void onError(String message) => errorMessage = message;

  Map<String, dynamic> toMap() => {
        'videoId': videoId,
        'ttffMs': ttffMs,
        'rebufferCount': rebufferCount,
        'totalRebufferMs': totalRebufferMs,
        'rebufferRatio': (rebufferRatio * 100).round() / 100.0,
        'watchTimeSec': watchTimeSeconds.round(),
        'completionRate': (completionRate * 100).round() / 100.0,
        'completed': completed,
        'seekCount': seekCount,
        'videoDurationSec': videoDuration.round(),
        'error': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
}

class ActiveVideoSessionSnapshot {
  final double watchTimeSeconds;
  final double completionRate;
  final double rebufferRatio;
  final bool hasFirstFrame;
  final bool isAudible;
  final bool hasStableFocus;

  const ActiveVideoSessionSnapshot({
    required this.watchTimeSeconds,
    required this.completionRate,
    required this.rebufferRatio,
    required this.hasFirstFrame,
    required this.isAudible,
    required this.hasStableFocus,
  });
}

class VideoTelemetryService {
  static VideoTelemetryService? _instance;
  static VideoTelemetryService? maybeFind() => _instance;

  static VideoTelemetryService ensure() =>
      maybeFind() ?? (_instance = VideoTelemetryService._internal());

  static VideoTelemetryService get instance => ensure();
  VideoTelemetryService._internal();

  final _userService = CurrentUserService.instance;
  final _activeSessions = <String, VideoSessionMetrics>{};
  bool _writesDisabled = false;

  bool get _canWrite {
    if (kDebugMode) return false;
    return !_writesDisabled;
  }

  /// Start tracking a video session.
  void startSession(String videoId, String videoUrl) {
    _activeSessions[videoId] =
        VideoSessionMetrics(videoId: videoId, videoUrl: videoUrl);
    recordQALabVideoEvent(
      code: 'video_session_started',
      message: 'Video session started',
      metadata: <String, dynamic>{
        'videoId': videoId,
        'videoUrl': videoUrl,
      },
    );
  }

  /// Record first frame rendered (TTFF).
  void onFirstFrame(String videoId) {
    _activeSessions[videoId]?.markFirstFrame();
    recordQALabVideoEvent(
      code: 'video_first_frame',
      message: 'Video rendered first frame',
      metadata: <String, dynamic>{'videoId': videoId},
    );
  }

  /// Record buffering start.
  void onBufferingStart(String videoId) {
    _activeSessions[videoId]?.onBufferingStart();
    recordQALabVideoEvent(
      code: 'video_buffering_started',
      message: 'Video buffering started',
      metadata: <String, dynamic>{'videoId': videoId},
    );
  }

  /// Record buffering end.
  void onBufferingEnd(String videoId) {
    _activeSessions[videoId]?.onBufferingEnd();
    recordQALabVideoEvent(
      code: 'video_buffering_ended',
      message: 'Video buffering ended',
      metadata: <String, dynamic>{'videoId': videoId},
    );
  }

  /// Record position update.
  void onPositionUpdate(String videoId, double position, double duration) {
    _activeSessions[videoId]?.onPositionUpdate(position, duration);
  }

  /// Record seek.
  void onSeek(String videoId) {
    _activeSessions[videoId]?.onSeek();
  }

  /// Record completion.
  void onCompleted(String videoId) {
    _activeSessions[videoId]?.onCompleted();
  }

  /// Record error.
  void onError(String videoId, String message) {
    _activeSessions[videoId]?.onError(message);
    recordQALabVideoEvent(
      code: 'video_error',
      message: message,
      metadata: <String, dynamic>{'videoId': videoId},
    );
  }

  void updateRuntimeHints(
    String videoId, {
    bool? isAudible,
    bool? hasStableFocus,
  }) {
    final session = _activeSessions[videoId];
    if (session == null) return;
    if (isAudible != null) {
      session.isAudible = isAudible;
    }
    if (hasStableFocus != null) {
      session.hasStableFocus = hasStableFocus;
    }
  }

  ActiveVideoSessionSnapshot? activeSessionSnapshot(String videoId) {
    final session = _activeSessions[videoId];
    if (session == null) return null;
    return ActiveVideoSessionSnapshot(
      watchTimeSeconds: session.watchTimeSeconds,
      completionRate: session.completionRate,
      rebufferRatio: session.rebufferRatio,
      hasFirstFrame: session.firstFrameAt != null,
      isAudible: session.isAudible,
      hasStableFocus: session.hasStableFocus,
    );
  }

  /// End session and flush metrics to Firestore.
  Future<void> endSession(String videoId) async {
    final session = _activeSessions.remove(videoId);
    if (session == null) return;
    recordQALabVideoEvent(
      code: 'video_session_ended',
      message: 'Video session ended',
      metadata: <String, dynamic>{
        'videoId': videoId,
        'ttffMs': session.ttffMs,
        'rebufferCount': session.rebufferCount,
        'totalRebufferMs': session.totalRebufferMs,
        'completionRate': session.completionRate,
        'completed': session.completed,
        'isAudible': session.isAudible,
        'hasStableFocus': session.hasStableFocus,
      },
    );
    await _flush(session);
  }

  /// End all active sessions (app lifecycle).
  Future<void> endAllSessions() async {
    final sessions = Map<String, VideoSessionMetrics>.from(_activeSessions);
    _activeSessions.clear();
    for (final session in sessions.values) {
      await _flush(session);
    }
  }

  Future<void> _flush(VideoSessionMetrics session) async {
    if (!_canWrite) return;
    final uid = _userService.effectiveUserId;
    if (uid.isEmpty) return;
    // Skip very short sessions (less than 1 second watch time).
    if (session.watchTimeSeconds < 1.0) return;

    try {
      await FirebaseFirestore.instance
          .collection('Analytics')
          .doc('VideoPlayback')
          .collection(uid)
          .add(session.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _writesDisabled = true;
      }
    } catch (_) {
      // Silent fail for analytics
    }
  }
}
