import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ResponsiveAuditFinding {
  const ResponsiveAuditFinding({
    required this.severity,
    required this.message,
  });

  final String severity;
  final String message;

  @override
  String toString() => '[$severity] $message';
}

Future<List<ResponsiveAuditFinding>> collectResponsiveAuditFindings(
  WidgetTester tester, {
  Finder? criticalCta,
  Finder? criticalInput,
  Finder? header,
}) async {
  final findings = <ResponsiveAuditFinding>[];
  _collectTakeExceptionFailures(tester, findings);

  final renderErrors = <FlutterErrorDetails>[];
  final oldOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    renderErrors.add(details);
  };
  addTearDown(() => FlutterError.onError = oldOnError);
  await tester.pump();

  for (final details in renderErrors) {
    final text = details.exceptionAsString();
    if (text.contains('RenderFlex overflowed')) {
      findings.add(
        ResponsiveAuditFinding(
          severity: 'fail',
          message: 'render overflow: $text',
        ),
      );
    }
  }

  if (criticalCta != null && !_isFinderVisibleInViewport(tester, criticalCta)) {
    findings.add(
      const ResponsiveAuditFinding(
        severity: 'fail',
        message: 'primary CTA not visible',
      ),
    );
  }
  if (criticalInput != null &&
      !_isFinderVisibleInViewport(tester, criticalInput)) {
    findings.add(
      const ResponsiveAuditFinding(
        severity: 'fail',
        message: 'critical input not visible',
      ),
    );
  }
  if (header != null && !_isFinderVisibleInViewport(tester, header)) {
    findings.add(
      const ResponsiveAuditFinding(
        severity: 'warning',
        message: 'header not found on surface',
      ),
    );
  }

  return findings;
}

void _collectTakeExceptionFailures(
  WidgetTester tester,
  List<ResponsiveAuditFinding> findings,
) {
  while (true) {
    final dynamic exception = tester.takeException();
    if (exception == null) {
      break;
    }
    findings.add(
      ResponsiveAuditFinding(
        severity: 'fail',
        message: 'layout exception: $exception',
      ),
    );
  }
}

bool _isFinderVisibleInViewport(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return false;
  }
  final rect = tester.getRect(finder.first);
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  final viewport = Offset.zero & view;
  return rect.overlaps(viewport);
}

void expectNoResponsiveAuditFailures(
  List<ResponsiveAuditFinding> findings, {
  String? reason,
}) {
  final fails = findings.where((item) => item.severity == 'fail').toList();
  expect(
    fails,
    isEmpty,
    reason: reason ??
        fails.map((item) => item.toString()).join('\n'),
  );
}

String summarizeResponsiveAuditFindings(List<ResponsiveAuditFinding> findings) {
  if (findings.isEmpty) {
    return '[pass] invariant korunuyor';
  }
  return findings.map((item) => item.toString()).join(' | ');
}

void logResponsiveAuditFindings({
  required String screen,
  required String variant,
  required List<ResponsiveAuditFinding> findings,
}) {
  debugPrint(
    '[responsive-audit][$screen][$variant] '
    '${summarizeResponsiveAuditFindings(findings)}',
  );
}
