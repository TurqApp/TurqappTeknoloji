import 'dart:async';
import 'dart:ui' show FrameTiming;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/Settings/qa_lab_view.dart';

import 'qa_lab_mode.dart';
import 'qa_lab_recorder.dart';

bool _qaLabAutoOpened = false;
bool _qaLabLaunchAutoOpenScheduled = false;

void ensureQALabIfEnabled() {
  if (!QALabMode.enabled) return;
  final recorder = QALabRecorder.ensure();
  unawaited(recorder.refreshPermissionSnapshot(trigger: 'bootstrap'));
}

void scheduleQALabAutoOpenOnLaunch() {
  if (!QALabMode.enabled || !QALabMode.autoStartSession) return;
  if (_qaLabAutoOpened || _qaLabLaunchAutoOpenScheduled) return;
  _qaLabLaunchAutoOpenScheduled = true;

  Future<void>.delayed(const Duration(seconds: 6), () {
    _qaLabLaunchAutoOpenScheduled = false;
    _openQALabIfNeeded(trigger: 'launch_delay');
  });
}

Future<void> prepareQALabFreshStartIfNeeded({
  String trigger = 'launch',
}) async {
  if (!QALabMode.enabled || !QALabMode.freshStartOnLaunch) {
    return;
  }
  await QALabRecorder.ensure().prepareFreshStart(trigger: trigger);
}

void recordQALabRouteChange({
  required String current,
  required String previous,
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordRouteChange(
    current: current,
    previous: previous,
  );
  final normalizedRoute = current.trim().toLowerCase();
  if (normalizedRoute.contains('qa_lab') || normalizedRoute.contains('qalab')) {
    _qaLabAutoOpened = true;
  }
}

void _openQALabIfNeeded({required String trigger}) {
  if (_qaLabAutoOpened) return;

  final currentRoute = Get.currentRoute.trim().toLowerCase();
  if (currentRoute.contains('qa_lab') || currentRoute.contains('qalab')) {
    _qaLabAutoOpened = true;
    return;
  }

  _qaLabAutoOpened = true;
  QALabRecorder.ensure().captureCheckpoint(
    label: 'qa_lab_autostart_open',
    surface: 'app',
    extra: <String, dynamic>{
      'trigger': trigger,
      'route': currentRoute,
    },
  );
  unawaited(
    Get.offAll<void>(() => const QALabView()) ?? Future<void>.value(),
  );
}

void recordQALabFlutterError(
  FlutterErrorDetails details, {
  bool suppressed = false,
  String sourceLabel = 'flutter',
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordFlutterError(
    details,
    suppressed: suppressed,
    sourceLabel: sourceLabel,
  );
}

void recordQALabPlatformError(
  Object error,
  StackTrace stackTrace, {
  bool suppressed = false,
  String sourceLabel = 'platform',
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordPlatformError(
    error,
    stackTrace,
    suppressed: suppressed,
    sourceLabel: sourceLabel,
  );
}

void recordQALabHandledError({
  required String code,
  required String message,
  required String severity,
  required Map<String, dynamic> metadata,
  String? stackTrace,
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordHandledError(
    code: code,
    message: message,
    severity: severity,
    metadata: metadata,
    stackTrace: stackTrace,
  );
}

void recordQALabCacheFirstEvent(Map<String, dynamic> payload) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordCacheFirstEvent(payload);
}

void recordQALabVideoEvent({
  required String code,
  required String message,
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordVideoEvent(
    code: code,
    message: message,
    metadata: metadata,
  );
}

void recordQALabFrameTimings(List<FrameTiming> timings) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordFrameTimings(timings);
}

void recordQALabLifecycleState(String state) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordLifecycleState(state);
}

Future<void> refreshQALabPermissionSnapshot({
  String trigger = 'manual',
}) async {
  if (!QALabMode.enabled) return;
  await QALabRecorder.ensure().refreshPermissionSnapshot(trigger: trigger);
}

void captureQALabCheckpoint({
  required String label,
  required String surface,
  Map<String, dynamic> extra = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().captureCheckpoint(
    label: label,
    surface: surface,
    extra: extra,
  );
}

void recordQALabScrollEvent({
  required String surface,
  required String phase,
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordScrollEvent(
    surface: surface,
    phase: phase,
    metadata: metadata,
  );
}

void recordQALabFeedFetchEvent({
  required String stage,
  String surface = 'feed',
  String trigger = 'manual',
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordFeedFetchEvent(
    surface: surface,
    stage: stage,
    trigger: trigger,
    metadata: metadata,
  );
}

void recordQALabAdEvent({
  required String stage,
  String? surface,
  String placement = '',
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordAdEvent(
    surface: surface,
    stage: stage,
    placement: placement,
    metadata: metadata,
  );
}

void recordQALabPlaybackDispatch({
  required String surface,
  required String stage,
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure().recordPlaybackDispatch(
    surface: surface,
    stage: stage,
    metadata: metadata,
  );
}
