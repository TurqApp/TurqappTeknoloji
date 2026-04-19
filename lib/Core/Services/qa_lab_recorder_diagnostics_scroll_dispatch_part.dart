part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollDispatchPart on QALabRecorder {
  QALabTimelineEvent? _firstPlaybackDispatchAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isEffectivePlaybackDispatchForScroll)
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .firstOrNull;
  }

  QALabTimelineEvent? _latestPlaybackSkipAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where((event) => !_isEffectivePlaybackDispatchForScroll(event))
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .lastOrNull;
  }

  List<Map<String, dynamic>> _duplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
    String? docId,
    DateTime? after,
  }) {
    final events = surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isIssuedPlaybackDispatch)
        .where((event) => after == null || !event.timestamp.isBefore(after))
        .where(
          (event) =>
              docId == null ||
              (event.metadata['docId'] ?? '').toString() == docId,
        )
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < events.length; i++) {
      final first = events[i];
      final firstDocId = (first.metadata['docId'] ?? '').toString();
      if (firstDocId.isEmpty) continue;
      final stages = <String>[first.code];
      var repeatCount = 1;
      for (int j = i + 1; j < events.length; j++) {
        final next = events[j];
        if ((next.metadata['docId'] ?? '').toString() != firstDocId) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicatePlaybackDispatchWindowMs) {
          break;
        }
        repeatCount += 1;
        stages.add(next.code);
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'docId': firstDocId,
            'repeatCount': repeatCount,
            'stages': stages,
            'sources': <String>[
              (first.metadata['dispatchSource'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['dispatchSource'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'callerSignatures': <String>[
              (first.metadata['callerSignature'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['callerSignature'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'scrollToken': (first.metadata['scrollToken'] ?? '').toString(),
            'windowMs': QALabMode.duplicatePlaybackDispatchWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  bool _isBenignShortDuplicatePlaybackBurst(
    Map<String, dynamic> burst, {
    bool hasVisualConfirmation = false,
  }) {
    if (_asInt(burst['repeatCount']) != 2) {
      return false;
    }
    final stages = (burst['stages'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (stages.isEmpty) {
      return false;
    }
    if (stages.every((stage) => stage == 'short_page_play')) {
      return true;
    }
    return hasVisualConfirmation &&
        stages.every(
          (stage) =>
              stage == 'short_page_play' ||
              stage == 'short_watchdog_play_retry',
        );
  }

  bool _isIssuedPlaybackDispatch(QALabTimelineEvent event) {
    final raw = event.metadata['dispatchIssued'];
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() != 'false';
    }
    return true;
  }

  bool _isEffectivePlaybackDispatchForScroll(QALabTimelineEvent event) {
    if (_isIssuedPlaybackDispatch(event)) return true;
    final code = event.code.trim();
    final skipReason = (event.metadata['skipReason'] ?? '').toString().trim();
    if (code == 'feed_card_manager_resume_current') {
      return true;
    }
    if (code == 'feed_card_adapter_play_skipped' &&
        skipReason == 'already_playing') {
      return true;
    }
    if (code == 'short_page_play_skipped' && skipReason == 'already_playing') {
      return true;
    }
    if (code == 'short_page_targeted' && skipReason == 'page_activated') {
      return true;
    }
    return false;
  }

  int _countDuplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _duplicatePlaybackDispatchBursts(surfaceTimeline: surfaceTimeline)
        .length;
  }
}
