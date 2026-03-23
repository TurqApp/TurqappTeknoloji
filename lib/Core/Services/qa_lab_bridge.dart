import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'qa_lab_mode.dart';
import 'qa_lab_recorder.dart';

void ensureQALabIfEnabled() {
  if (!QALabMode.enabled) return;
  QALabRecorder.ensure();
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
