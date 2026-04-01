part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsStateFeedPart on QALabRecorder {
  bool _feedProbeAsBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  List<QALabPinpointFinding> _buildFeedShortStateSpecificFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
    required QALabCheckpoint? latestCheckpoint,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];

    if (surface == 'feed') {
      final count = _asInt(latestProbe['count']);
      final centeredIndex = _asInt(latestProbe['centeredIndex']);
      final rootProbe = latestCheckpoint?.probe ?? const <String, dynamic>{};
      final isFeedForeground = _isPrimaryFeedSelected(
        rootProbe,
        route: route,
      );
      if (isFeedForeground &&
          count > 0 &&
          (centeredIndex < 0 || centeredIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'feed_centered_index_invalid',
            message:
                'Feed has visible items but centered index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'centeredIndex': centeredIndex,
            },
          ),
        );
      }
      final centeredDocId = (latestProbe['centeredDocId'] ?? '').toString();
      final centeredHasPlayableVideo = _feedProbeAsBool(
        latestProbe['centeredHasPlayableVideo'],
        fallback: false,
      );
      final centeredHasRenderableVideoCard = _feedProbeAsBool(
        latestProbe['centeredHasRenderableVideoCard'],
        fallback: false,
      );
      if (count > 0 &&
          centeredDocId.isNotEmpty &&
          centeredHasRenderableVideoCard &&
          !centeredHasPlayableVideo) {
        final observedSince = _playbackObservationStart(
          surfaceCheckpoints: surfaceCheckpoints,
          route: route,
          surface: surface,
          expectedDocId: centeredDocId,
        );
        final elapsedMs =
            referenceTime.difference(observedSince).inMilliseconds;
        if (elapsedMs >= QALabMode.autoplayDetectionGraceMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.warning,
              code: 'feed_video_source_not_ready',
              message:
                  'Feed centered item exposed a video card, but playback source stayed unavailable after the grace window.',
              route: route,
              surface: surface,
              timestamp: referenceTime,
              context: <String, dynamic>{
                'docId': centeredDocId,
                'elapsedMs': elapsedMs,
                'hasRenderableVideoCard': centeredHasRenderableVideoCard,
                'hasPlayableVideo': centeredHasPlayableVideo,
              },
            ),
          );
        }
      }
      final playbackSuspended = _feedProbeAsBool(
        latestProbe['playbackSuspended'],
        fallback: false,
      );
      final pauseAll = _feedProbeAsBool(
        latestProbe['pauseAll'],
        fallback: false,
      );
      final canClaimPlaybackNow = _feedProbeAsBool(
        latestProbe['canClaimPlaybackNow'],
        fallback: false,
      );
      if (isFeedForeground &&
          count > 0 &&
          !_isQALabAutostartWarmup(
            surface: surface,
            route: route,
            referenceTime: referenceTime,
          ) &&
          (playbackSuspended || pauseAll || !canClaimPlaybackNow)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'feed_playback_gate_blocked',
            message:
                'Feed has content but playback gate is not eligible for autoplay.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'playbackSuspended': playbackSuspended,
              'pauseAll': pauseAll,
              'canClaimPlaybackNow': canClaimPlaybackNow,
            },
          ),
        );
      }
    } else if (surface == 'short') {
      final count = _asInt(latestProbe['count']);
      final activeIndex = _asInt(latestProbe['activeIndex']);
      if (count > 0 && (activeIndex < 0 || activeIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'short_active_index_invalid',
            message:
                'Short surface has items but active index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'activeIndex': activeIndex,
            },
          ),
        );
      }
    }

    return findings;
  }
}
