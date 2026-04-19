import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

abstract class PlaybackExecutionStrategy {
  const PlaybackExecutionStrategy();

  void primeAdapter(HLSVideoAdapter adapter);

  void applyPresentation(
    HLSVideoAdapter adapter, {
    required bool shouldBeAudible,
  });

  Future<void> playAdapter(HLSVideoAdapter adapter);

  Future<void> pauseAdapter(HLSVideoAdapter adapter);

  Future<void> quietBackgroundAdapter(HLSVideoAdapter adapter);

  Future<void> stopAdapter(HLSVideoAdapter adapter);

  void quietHandle(
    PlaybackHandle handle, {
    void Function()? persistState,
    bool stopPlayback = false,
  });

  void resumeHandle(PlaybackHandle handle);
}

class PlaybackExecutionService {
  const PlaybackExecutionService({
    this.platformOverride,
  });

  final TargetPlatform? platformOverride;

  PlaybackExecutionStrategy get _strategy {
    switch (platformOverride ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        return const _AndroidPlaybackExecutionStrategy();
      case TargetPlatform.iOS:
        return const _IosPlaybackExecutionStrategy();
      default:
        return const _DefaultPlaybackExecutionStrategy();
    }
  }

  void primeAdapter(HLSVideoAdapter adapter) {
    _strategy.primeAdapter(adapter);
  }

  void applyPresentation(
    HLSVideoAdapter adapter, {
    required bool shouldBeAudible,
  }) {
    _strategy.applyPresentation(
      adapter,
      shouldBeAudible: shouldBeAudible,
    );
  }

  Future<void> playAdapter(HLSVideoAdapter adapter) {
    return _strategy.playAdapter(adapter);
  }

  Future<void> pauseAdapter(HLSVideoAdapter adapter) {
    return _strategy.pauseAdapter(adapter);
  }

  Future<void> quietBackgroundAdapter(HLSVideoAdapter adapter) {
    return _strategy.quietBackgroundAdapter(adapter);
  }

  Future<void> stopAdapter(HLSVideoAdapter adapter) {
    return _strategy.stopAdapter(adapter);
  }

  void quietHandle(
    PlaybackHandle handle, {
    void Function()? persistState,
    bool stopPlayback = false,
  }) {
    _strategy.quietHandle(
      handle,
      persistState: persistState,
      stopPlayback: stopPlayback,
    );
  }

  void resumeHandle(PlaybackHandle handle) {
    _strategy.resumeHandle(handle);
  }
}

class _BasePlaybackExecutionStrategy implements PlaybackExecutionStrategy {
  const _BasePlaybackExecutionStrategy();

  @override
  void primeAdapter(HLSVideoAdapter adapter) {
    unawaited(adapter.setVolume(0.0));
  }

  @override
  void applyPresentation(
    HLSVideoAdapter adapter, {
    required bool shouldBeAudible,
  }) {
    unawaited(adapter.setVolume(shouldBeAudible ? 1.0 : 0.0));
  }

  @override
  Future<void> playAdapter(HLSVideoAdapter adapter) {
    return adapter.play();
  }

  @override
  Future<void> pauseAdapter(HLSVideoAdapter adapter) {
    return adapter.pause();
  }

  @override
  Future<void> quietBackgroundAdapter(HLSVideoAdapter adapter) {
    return adapter.forceSilence();
  }

  @override
  Future<void> stopAdapter(HLSVideoAdapter adapter) {
    return adapter.silenceAndStopPlayback();
  }

  @override
  void quietHandle(
    PlaybackHandle handle, {
    void Function()? persistState,
    bool stopPlayback = false,
  }) {
    try {
      if (handle.isInitialized) {
        persistState?.call();
      }
    } catch (_) {}

    if (handle is HLSAdapterPlaybackHandle) {
      unawaited(
        stopPlayback
            ? stopAdapter(handle.adapter)
            : quietBackgroundAdapter(handle.adapter),
      );
      return;
    }

    if (stopPlayback) {
      try {
        unawaited(handle.stop());
      } catch (_) {}
      return;
    }

    try {
      unawaited(handle.setVolume(0.0));
    } catch (_) {}
    try {
      unawaited(handle.pause());
    } catch (_) {}
  }

  @override
  void resumeHandle(PlaybackHandle handle) {
    unawaited(handle.play());
  }
}

class _AndroidPlaybackExecutionStrategy extends _BasePlaybackExecutionStrategy {
  const _AndroidPlaybackExecutionStrategy();
}

class _IosPlaybackExecutionStrategy extends _BasePlaybackExecutionStrategy {
  const _IosPlaybackExecutionStrategy();

  @override
  Future<void> stopAdapter(HLSVideoAdapter adapter) {
    if (adapter.preferWarmPoolPause) {
      return quietBackgroundAdapter(adapter);
    }
    return super.stopAdapter(adapter);
  }
}

class _DefaultPlaybackExecutionStrategy extends _BasePlaybackExecutionStrategy {
  const _DefaultPlaybackExecutionStrategy();
}
