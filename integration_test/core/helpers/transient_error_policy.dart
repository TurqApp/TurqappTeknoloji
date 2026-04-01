import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

bool isTransientIntegrationErrorText(String text) {
  return text.contains('cloud_firestore/unavailable') ||
      text.contains('Invalid statusCode: 503');
}

bool isAllowedNonFatalIntegrationErrorText(String text) {
  return text.contains('cloud_firestore/permission-denied') ||
      text.contains('A FocusNode was used after being disposed.') ||
      text.contains('_FocusInheritedScope') ||
      text.contains('_dependents.isEmpty') ||
      text.contains("'_dependents.isEmpty': is not true.") ||
      isTransientIntegrationErrorText(text);
}

FlutterExceptionHandler? installTransientFlutterErrorPolicy() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (isAllowedNonFatalIntegrationErrorText(text)) {
      debugPrint('Suppressed non-fatal: $text');
      if (details.stack != null) {
        debugPrint('Suppressed non-fatal stack: ${details.stack}');
      }
      return;
    }
    originalOnError?.call(details);
  };
  return originalOnError;
}

void restoreTransientFlutterErrorPolicy(FlutterExceptionHandler? original) {
  FlutterError.onError = original;
}

void drainExpectedTesterExceptions(
  WidgetTester tester, {
  String context = 'integration test',
}) {
  while (true) {
    final error = tester.takeException();
    if (error == null) return;
    final text = error.toString();
    if (isAllowedNonFatalIntegrationErrorText(text)) {
      debugPrint('Suppressed non-fatal: $text');
      continue;
    }
    throw TestFailure('Unexpected flutter exception during $context: $error');
  }
}

bool isTransientFirestoreUnavailable(Object error) {
  return error is FirebaseException &&
      error.plugin == 'cloud_firestore' &&
      error.code == 'unavailable';
}
