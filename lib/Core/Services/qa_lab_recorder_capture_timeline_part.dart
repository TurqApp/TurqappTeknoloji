part of 'qa_lab_recorder.dart';

extension QALabRecorderCaptureTimelinePart on QALabRecorder {
  void recordVideoEvent({
    required String code,
    required String message,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final snapshot = IntegrationTestStateProbe.snapshot();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    final videoId =
        ((metadata['videoId'] ?? metadata['docId']) ?? '').toString().trim();
    if ((code == 'video_buffering_started' ||
            code == 'video_buffering_ended') &&
        _isRateLimited(
          'video_buffering|$surface|$videoId|$code',
          code == 'video_buffering_started'
              ? const Duration(seconds: 4)
              : const Duration(seconds: 2),
        )) {
      return;
    }
    final severity = code.contains('error') || code.contains('timeout')
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.info;
    recordIssue(
      source: QALabIssueSource.video,
      code: code,
      severity: severity,
      message: message,
      metadata: metadata,
    );
  }

  void recordScrollEvent({
    required String surface,
    required String phase,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'scroll',
      code: phase,
      surface: surface,
      metadata: metadata,
    );
  }

  void recordFeedFetchEvent({
    required String surface,
    required String stage,
    required String trigger,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'feed_fetch',
      code: stage,
      surface: surface,
      metadata: <String, dynamic>{
        'trigger': trigger,
        ...metadata,
      },
    );
  }

  void recordAdEvent({
    String? surface,
    required String stage,
    required String placement,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'ad',
      code: stage,
      surface: (surface ?? '').trim(),
      metadata: <String, dynamic>{
        'placement': placement,
        ...metadata,
      },
    );
  }

  void recordPlaybackDispatch({
    required String surface,
    required String stage,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'playback_dispatch',
      code: stage,
      surface: surface,
      metadata: metadata,
    );
  }
}
