part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsStateSurfacePart on QALabRecorder {
  List<QALabPinpointFinding> _buildSurfaceStateSpecificFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
    required QALabCheckpoint? latestCheckpoint,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];

    findings.addAll(
      _buildFeedShortStateSpecificFindings(
        surface: surface,
        latestProbe: latestProbe,
        latestCheckpoint: latestCheckpoint,
        surfaceCheckpoints: surfaceCheckpoints,
        referenceTime: referenceTime,
        route: route,
      ),
    );

    if (surface == 'chat') {
      final conversationProbe = latestCheckpoint?.probe['chatConversation']
              as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final lastMediaFailureCode =
          (conversationProbe['lastMediaFailureCode'] ?? '').toString();
      if (lastMediaFailureCode.isNotEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'chat_media_failure',
            message: 'Chat media pipeline reported a failure code.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'lastMediaFailureCode': lastMediaFailureCode,
              'lastMediaFailureDetail':
                  (conversationProbe['lastMediaFailureDetail'] ?? '')
                      .toString(),
              'lastMediaAction':
                  (conversationProbe['lastMediaAction'] ?? '').toString(),
            },
          ),
        );
      }
    } else if (surface == 'notifications') {
      final lastOpenedNotificationId =
          (latestProbe['lastOpenedNotificationId'] ?? '').toString();
      final lastOpenedRouteKind =
          (latestProbe['lastOpenedRouteKind'] ?? '').toString();
      if (lastOpenedNotificationId.isNotEmpty && lastOpenedRouteKind.isEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'notifications_route_resolution_missing',
            message:
                'A notification was opened but route resolution metadata stayed empty.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'notificationId': lastOpenedNotificationId,
            },
          ),
        );
      }
    }

    return findings;
  }
}
