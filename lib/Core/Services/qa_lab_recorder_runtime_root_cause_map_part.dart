part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeRootCauseMapPart on QALabRecorder {
  (String, String)? _inferMappedPrimaryRootCause({
    required QALabSurfaceDiagnostic diagnostic,
    required String headlineCode,
  }) {
    final runtime = diagnostic.runtime;
    final code = headlineCode.trim().toLowerCase();

    if (code.contains('blank_surface')) {
      return (
        'data_absent',
        '${diagnostic.surface} loaded as an empty authenticated surface.',
      );
    }
    if (code.contains('autoplay') || code.contains('playback_gate')) {
      return (
        'autoplay_dispatch',
        '${diagnostic.surface} had eligible content but autoplay did not lock onto the expected video.',
      );
    }
    if (code.contains('duplicate_fetch')) {
      return (
        'feed_trigger_duplication',
        '${diagnostic.surface} triggered repeated feed loads before a prior fetch settled.',
      );
    }
    if (code.contains('duplicate_playback_dispatch')) {
      return (
        'playback_dispatch_duplication',
        '${diagnostic.surface} issued repeated playback commands against the same item in a tight burst.',
      );
    }
    if (code.contains('scroll_dispatch') ||
        code.contains('scroll_first_frame')) {
      return (
        'scroll_autoplay_latency',
        '${diagnostic.surface} lost time between scroll settle, playback dispatch, and the first rendered frame.',
      );
    }
    if (code.contains('first_frame')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} started playback but first frame confirmation lagged or never arrived.',
      );
    }
    if (code.contains('black_screen')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} reattached video layers before a stable first frame and risks blank flashes.',
      );
    }
    if (code.contains('buffer_stall') || code.contains('rebuffer')) {
      return (
        'buffering_instability',
        '${diagnostic.surface} playback spent too long buffering or repeatedly rebuffered.',
      );
    }
    if (code.contains('audio_state') || code.contains('mute')) {
      return (
        'audio_state_drift',
        '${diagnostic.surface} produced inconsistent audible state across video sessions.',
      );
    }
    if (code.contains('thumbnail_only')) {
      return (
        'playback_session_loss',
        '${diagnostic.surface} had prior video success in the session but later regressed to thumbnail-only playback.',
      );
    }
    if (code.contains('ad_load') || code.contains('ad_retry')) {
      return (
        'ad_loading_latency',
        '${diagnostic.surface} ad lifecycle added delay, failure, or retry pressure during rendering.',
      );
    }
    if (code.contains('cache_live_failures') ||
        (runtime['cacheFailureCount'] as int? ?? 0) > 0) {
      return (
        'cache_live_sync',
        '${diagnostic.surface} cache-first flow preserved stale state or failed to refresh live data.',
      );
    }
    if (code.contains('permission')) {
      return (
        'permission_block',
        '${diagnostic.surface} is blocked by OS-level permission state.',
      );
    }
    if (code.contains('jank') || code.contains('noise_burst')) {
      return (
        'runtime_noise',
        '${diagnostic.surface} accumulated frame jank or suppressed runtime noise.',
      );
    }
    if (code.contains('lifecycle')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} was interrupted by app lifecycle transitions.',
      );
    }
    if (code.contains('interrupted')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} failed to recover cleanly after a fullscreen or background interruption.',
      );
    }
    if (code.contains('route_resolution')) {
      return (
        'route_resolution',
        '${diagnostic.surface} opened without completing target route resolution.',
      );
    }
    if (code.contains('media_failure')) {
      return (
        'media_pipeline',
        '${diagnostic.surface} reported a media pipeline failure.',
      );
    }
    if (code == 'coverage_gap') {
      return (
        'coverage_gap',
        '${diagnostic.surface} still has missing QA coverage tags.',
      );
    }

    return null;
  }
}
