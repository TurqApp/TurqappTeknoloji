import 'package:flutter/foundation.dart' show TargetPlatform;

class PlaybackSurfacePolicy {
  const PlaybackSurfacePolicy._();

  static const Duration defaultFeedAutoplayGateTimeout = Duration(
    milliseconds: 950,
  );
  static const Duration defaultFeedAutoplayGatePollInterval = Duration(
    milliseconds: 80,
  );
  static const Duration iosFeedStartupPlaybackLockDuration = Duration(
    milliseconds: 1200,
  );
  static const Duration iosFeedRefreshPlaybackLockDuration = Duration(
    milliseconds: 2200,
  );
  static const Duration iosFeedCenteredGapGrace = Duration(
    milliseconds: 480,
  );
  static const Duration iosPrimaryFeedRecoveryCooldown = Duration(
    milliseconds: 2500,
  );
  static const Duration iosFeedResumePositionCushion = Duration(
    milliseconds: 350,
  );

  static bool useTightAndroidWarmProfile({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
  }

  static int feedWarmFirstSegmentAheadCount({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool isOnCellular,
    required int defaultCount,
  }) {
    if ((platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isFeedStyleSurface) {
      return isOnCellular ? 3 : 5;
    }
    return defaultCount;
  }

  static int feedStartupWarmPlayableCount({
    required TargetPlatform platform,
    required bool isOnCellular,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return isOnCellular ? 4 : 6;
    }
    return defaultCount;
  }

  static int feedNativeStrongAheadCount({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool isOnCellular,
    required int defaultCount,
  }) {
    if ((platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isFeedStyleSurface) {
      return isOnCellular ? 2 : 5;
    }
    return defaultCount;
  }

  static int feedNativeWarmAheadPlayableCount({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool isOnCellular,
    required int defaultCount,
  }) {
    if ((platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isFeedStyleSurface) {
      return isOnCellular ? 2 : 5;
    }
    return defaultCount;
  }

  static double? feedPreferredBufferDurationSeconds({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool shouldPlay,
  }) {
    if ((platform != TargetPlatform.android && platform != TargetPlatform.iOS) ||
        !isFeedStyleSurface) {
      return null;
    }
    return shouldPlay ? 0.75 : 0.45;
  }

  static Duration feedAutoplayGateTimeout({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    if ((platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isFeedStyleSurface) {
      return const Duration(milliseconds: 250);
    }
    return defaultFeedAutoplayGateTimeout;
  }

  static Duration feedAutoplayGatePollInterval({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    if ((platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isFeedStyleSurface) {
      return const Duration(milliseconds: 40);
    }
    return defaultFeedAutoplayGatePollInterval;
  }

  static Duration feedPlaybackReassertDelay({
    required TargetPlatform platform,
    required int attempt,
  }) {
    if (platform == TargetPlatform.android) {
      return attempt == 0
          ? const Duration(milliseconds: 180)
          : const Duration(milliseconds: 120);
    }
    return attempt == 0
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 90);
  }

  static Duration feedStartupPlaybackLockDuration({
    required TargetPlatform platform,
    required Duration defaultDuration,
  }) {
    if (platform == TargetPlatform.iOS) {
      return iosFeedStartupPlaybackLockDuration;
    }
    return defaultDuration;
  }

  static Duration feedRefreshPlaybackLockDuration({
    required TargetPlatform platform,
    required Duration defaultDuration,
  }) {
    if (platform == TargetPlatform.iOS) {
      return iosFeedRefreshPlaybackLockDuration;
    }
    return defaultDuration;
  }

  static Duration feedCenteredGapPlaybackGrace({
    required TargetPlatform platform,
    required Duration androidDuration,
  }) {
    if (platform == TargetPlatform.android) {
      return androidDuration;
    }
    if (platform == TargetPlatform.iOS) {
      return iosFeedCenteredGapGrace;
    }
    return iosFeedCenteredGapGrace;
  }

  static bool supportsImmediateFeedHandoff({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool useLegacyIosFeedBehavior({
    required TargetPlatform platform,
    required bool isStandalonePostInstance,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS &&
        !isStandalonePostInstance &&
        !isFeedStyleSurface;
  }

  static bool useNativeIosFeedRecoveryAuthority({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool useLegacyIosFeedBehavior,
  }) {
    return platform == TargetPlatform.iOS &&
        isFeedStyleSurface &&
        !useLegacyIosFeedBehavior;
  }

  static bool shouldPreserveIosFeedPlaybackForResumeTransition({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool playbackSuspended,
    required int centeredIndex,
    required int modelIndex,
    required int? lastCenteredIndex,
  }) {
    if (platform != TargetPlatform.iOS) return false;
    if (!isFeedStyleSurface) return false;
    if (playbackSuspended) return true;
    if (centeredIndex != -1) return false;
    if (modelIndex < 0) return false;
    return lastCenteredIndex == modelIndex;
  }

  static bool shouldKeepIosFeedSurfaceAliveForBackScroll({
    required TargetPlatform platform,
    required bool keepPrimaryFeedSurfaceAliveInWarmWindow,
  }) {
    return platform == TargetPlatform.iOS &&
        keepPrimaryFeedSurfaceAliveInWarmWindow;
  }

  static Duration feedResumePositionCushion({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    if (platform == TargetPlatform.iOS && isFeedStyleSurface) {
      return iosFeedResumePositionCushion;
    }
    return Duration.zero;
  }

  static bool shouldZeroSavedResumePositionFallback({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS && isFeedStyleSurface;
  }

  static Duration feedRecoveryCooldown({
    required TargetPlatform platform,
    required Duration defaultDuration,
  }) {
    if (platform == TargetPlatform.iOS) {
      return iosPrimaryFeedRecoveryCooldown;
    }
    return defaultDuration;
  }

  static int feedRequiredAutoplaySegments({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    if (platform == TargetPlatform.android && isFeedStyleSurface) {
      return 1;
    }
    return 1;
  }

  static bool shouldBypassFeedSegmentDelayWhenInitialized({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.android && isFeedStyleSurface;
  }

  static bool preferDirectCdnForFeed({
    required TargetPlatform platform,
    required bool isPrimaryFeedSurface,
  }) {
    return (platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) &&
        isPrimaryFeedSurface;
  }

  static int feedPlaybackBoostLookAhead({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.iOS) {
      return defaultCount;
    }
    return defaultCount;
  }

  static int feedPlaybackBoostBehind({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.iOS) {
      return 0;
    }
    return defaultCount;
  }

  static bool shouldKeepFeedSurfaceAliveInWarmWindow({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool adapterBound,
    required bool hasRenderedFirstFrame,
    required bool hasResumeHint,
    required bool isStrongWarmTier,
    required bool isCacheOnlyWarmTier,
  }) {
    if (!isFeedStyleSurface) return false;
    if (platform == TargetPlatform.android) {
      return adapterBound && (isStrongWarmTier || isCacheOnlyWarmTier);
    }
    if (platform == TargetPlatform.iOS) {
      return hasRenderedFirstFrame && hasResumeHint && isStrongWarmTier;
    }
    return false;
  }

  static bool shouldDisableDirectionalFeedNativeWarmTier({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS && isFeedStyleSurface;
  }

  static bool shouldAllowFeedWarmControllerPreload({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool shouldPlay,
    required bool surfacePlaybackAllowed,
    required bool isPrimaryFeedSurface,
    required bool centeredWarmAnchorReady,
    required bool hasPlayableVideo,
  }) {
    final isAndroid = platform == TargetPlatform.android;
    final isIosPrimaryFeed =
        platform == TargetPlatform.iOS && isFeedStyleSurface;
    if (!isAndroid && !isIosPrimaryFeed) return false;
    if (isIosPrimaryFeed) return false;
    if (!isFeedStyleSurface || !hasPlayableVideo) return false;
    if (shouldPlay || !surfacePlaybackAllowed) return false;
    if (isAndroid && isPrimaryFeedSurface && !centeredWarmAnchorReady) {
      return false;
    }
    return true;
  }

  static bool shouldBypassSavedResumeHintForPrimaryFeed({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool isExplicitResumeRecoveryContext,
    required bool isStartupCacheOriginVideo,
    required int modelIndex,
  }) {
    if (platform == TargetPlatform.iOS) {
      return !isFeedStyleSurface;
    }
    if (platform != TargetPlatform.android) return false;
    if (!isFeedStyleSurface) return false;
    if (isExplicitResumeRecoveryContext) return false;
    if (!isStartupCacheOriginVideo) return false;
    return modelIndex == 0;
  }

  static bool shouldKeepFeedRuntimeHandleOnPause({
    required TargetPlatform platform,
    required bool isPrimaryFeedSurface,
    required bool keepAndroidSurfaceAlive,
  }) {
    if (keepAndroidSurfaceAlive) return true;
    return platform == TargetPlatform.iOS && isPrimaryFeedSurface;
  }

  static bool shouldDisposeFeedPlaybackForSurfaceLoss({
    required TargetPlatform platform,
    required bool isPrimaryFeedSurface,
    required bool isFloodSurface,
  }) {
    if (platform == TargetPlatform.android &&
        (isPrimaryFeedSurface || isFloodSurface)) {
      return true;
    }
    if (platform == TargetPlatform.iOS && isPrimaryFeedSurface) {
      return true;
    }
    if (isFloodSurface) {
      return true;
    }
    return false;
  }

  static bool shouldSuspendFeedPlaybackForOverlay({
    required TargetPlatform platform,
    required bool isPrimaryFeedSurface,
  }) {
    return platform == TargetPlatform.iOS && isPrimaryFeedSurface;
  }

  static int replayAdWarmupTarget({
    required TargetPlatform platform,
    required int defaultTarget,
  }) {
    if (platform == TargetPlatform.iOS) {
      return defaultTarget + 1;
    }
    return defaultTarget;
  }

  static bool shouldDisableDartRecoveryForPrimaryFeed({
    required TargetPlatform platform,
    required bool isPrimaryFeedSurface,
  }) {
    return isPrimaryFeedSurface &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.android);
  }

  static bool supportsFeedVisibleOwnerRetention({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool supportsFeedStartupTargetRetention({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool supportsFeedSwitchRetention({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool shouldUseFeedRefreshPlaybackLockWindow({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool canAttemptCurrentFeedRecovery({
    required TargetPlatform platform,
    required String? lastPlaybackCommandDocId,
    required String playbackKey,
    required DateTime? lastPlaybackCommandAt,
    required DateTime now,
    required Duration androidCurrentRecoveryGrace,
  }) {
    if (platform != TargetPlatform.android) {
      return true;
    }
    return lastPlaybackCommandDocId != playbackKey ||
        lastPlaybackCommandAt == null ||
        now.difference(lastPlaybackCommandAt) > androidCurrentRecoveryGrace;
  }

  static bool shouldUseZeroFeedImmediateClaimInterval({
    required TargetPlatform platform,
    required bool readyForImmediateHandoff,
  }) {
    return platform == TargetPlatform.iOS && readyForImmediateHandoff;
  }

  static bool shouldScheduleFeedPlaybackReassertOnMiss({
    required TargetPlatform platform,
    required bool pendingPlay,
  }) {
    return platform == TargetPlatform.iOS && !pendingPlay;
  }

  static bool shouldUseImmediateFeedResumeCapability({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool shouldUseFeedStartupWarmPreload({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.android;
  }

  static bool shouldScheduleFeedRefreshPlaybackReassert({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static Duration? feedRefreshPlaybackExtraKickDelay({
    required TargetPlatform platform,
  }) {
    if (platform == TargetPlatform.iOS) {
      return const Duration(milliseconds: 120);
    }
    return null;
  }

  static bool shouldPreserveFeedPendingResumeAnchorOnTabReset({
    required TargetPlatform platform,
    required bool hasPendingDocId,
  }) {
    return platform == TargetPlatform.iOS && hasPendingDocId;
  }

  static bool supportsFeedSavedResumeSeek({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.android ||
        (platform == TargetPlatform.iOS && isFeedStyleSurface);
  }

  static bool shouldThrottleFeedRecovery({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS && isFeedStyleSurface;
  }

  static bool shouldRecoverFrozenFeedPlayback({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool shouldPlay,
    required bool surfacePlaybackAllowed,
    required bool manualPauseRequested,
    required bool isInitialized,
    required bool isPlaying,
    required bool isBuffering,
    required bool isCompleted,
    required bool hasRenderedFirstFrame,
    required Duration position,
  }) {
    if (platform != TargetPlatform.iOS) return false;
    if (!isFeedStyleSurface) return false;
    if (!shouldPlay || !surfacePlaybackAllowed || manualPauseRequested) {
      return false;
    }
    if (!isInitialized || isPlaying || isBuffering || isCompleted) {
      return false;
    }
    return hasRenderedFirstFrame || position >= const Duration(milliseconds: 800);
  }

  static bool shouldMonitorFeedStall({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool shouldPlay,
    required bool surfacePlaybackAllowed,
    required bool manualPauseRequested,
    required bool isInitialized,
    required bool isCompleted,
  }) {
    if (!isFeedStyleSurface) return false;
    if (platform == TargetPlatform.android) return false;
    if (!shouldPlay || !surfacePlaybackAllowed || manualPauseRequested) {
      return false;
    }
    if (!isInitialized || isCompleted) return false;
    return true;
  }

  static bool shouldDeferInitialFeedStallRecovery({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool hasRenderedFirstFrame,
    required Duration position,
    required int stallRetryCount,
  }) {
    return platform == TargetPlatform.iOS &&
        isFeedStyleSurface &&
        hasRenderedFirstFrame &&
        position <= const Duration(milliseconds: 120) &&
        stallRetryCount == 0;
  }

  static bool shouldHoldFeedAudibilityOnOwnerCandidate({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool shouldPlay,
    required bool surfacePlaybackAllowed,
    required bool isOwnerCandidate,
    required bool hasRenderedFirstFrame,
    required Duration position,
    required bool isCompleted,
  }) {
    return platform == TargetPlatform.iOS &&
        isFeedStyleSurface &&
        shouldPlay &&
        surfacePlaybackAllowed &&
        isOwnerCandidate &&
        hasRenderedFirstFrame &&
        position > Duration.zero &&
        !isCompleted;
  }

  static bool shouldUseDirectFeedBootstrapClaim({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS && isFeedStyleSurface;
  }

  static bool shouldReassertStoppedFeedOwner({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
    required bool currentOwner,
    required Duration position,
    required bool isCompleted,
    required Duration stableFrameThreshold,
  }) {
    return platform == TargetPlatform.android &&
        isFeedStyleSurface &&
        currentOwner &&
        position >= stableFrameThreshold &&
        !isCompleted;
  }

  static bool shouldRestartStoppedInlineFeedOwner({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.android ||
        (platform == TargetPlatform.iOS && isFeedStyleSurface);
  }

  static bool preferStableFeedStartupBuffer({
    required TargetPlatform platform,
    required bool isFeedStyleSurface,
  }) {
    return platform == TargetPlatform.iOS && isFeedStyleSurface;
  }

  static bool preferStableFeedStartupWarmBuffer({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool preferDirectCdnForShort({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
  }

  static bool preferStableShortStartupBuffer({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  static bool preferStableDynamicShortStartupBuffer({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.android;
  }

  static int floodFocusedQueuePlayableCount({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    return platform == TargetPlatform.iOS ? defaultCount + 1 : defaultCount;
  }

  static int floodStrongReadyCount({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    return platform == TargetPlatform.iOS ? defaultCount + 1 : defaultCount;
  }

  static int floodRouteEntryStrongReadyCount({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    return platform == TargetPlatform.iOS ? defaultCount + 1 : defaultCount;
  }

  static int floodRouteEntryQueuePlayableCount({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    return platform == TargetPlatform.iOS ? defaultCount + 1 : defaultCount;
  }

  static bool shouldUseDirectShortOwnershipRequest({
    required TargetPlatform platform,
    required bool isPlaying,
    required bool isBuffering,
    required bool hasRenderedFirstFrame,
    required Duration position,
  }) {
    return platform == TargetPlatform.iOS &&
        (isPlaying ||
            isBuffering ||
            hasRenderedFirstFrame ||
            position > Duration.zero);
  }

  static bool supportsImmediateShortHandoff({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static Duration shortScrollDebounceDelay({
    required TargetPlatform platform,
    required Duration androidDelay,
  }) {
    if (platform == TargetPlatform.android) {
      return androidDelay;
    }
    if (platform == TargetPlatform.iOS) {
      return const Duration(milliseconds: 60);
    }
    return const Duration(milliseconds: 60);
  }

  static int shortForwardWarmFirstSegmentAheadCount({
    required TargetPlatform platform,
    required bool isOnCellular,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return isOnCellular ? 2 : 5;
    }
    return defaultCount;
  }

  static int shortActiveReadySegments({
    required TargetPlatform platform,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return defaultCount;
    }
    return defaultCount;
  }

  static int shortNeighborReadySegments({
    required TargetPlatform platform,
    required bool useTightWarmProfile,
    required int defaultCount,
  }) {
    if (platform == TargetPlatform.android) {
      return useTightWarmProfile ? 1 : defaultCount;
    }
    if (platform == TargetPlatform.iOS) {
      return defaultCount;
    }
    return defaultCount;
  }

  static bool shouldKeepTrimmedShortAdapterWarm({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  static bool shouldRecoverShortPlaybackOnRevisit({
    required TargetPlatform platform,
    required bool hasRenderedFirstFrame,
    required Duration position,
    required bool isCompleted,
  }) {
    return platform == TargetPlatform.iOS &&
        hasRenderedFirstFrame &&
        position >= const Duration(milliseconds: 800) &&
        !isCompleted;
  }

  static bool shouldKeepWarmShortNeighborAudible({
    required TargetPlatform platform,
    required bool isWarmNeighbor,
  }) {
    return platform == TargetPlatform.iOS && isWarmNeighbor;
  }

  static bool shouldPreserveShortAdapterOnRouteReturn({
    required TargetPlatform platform,
    required bool forceResumePosterOnReturn,
    required bool hadActiveAdapter,
  }) {
    return platform != TargetPlatform.android &&
        forceResumePosterOnReturn &&
        hadActiveAdapter;
  }

  static bool shouldEnsureWarmNeighborAdapter({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool shouldRecordShortVisibleView({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS;
  }

  static bool shouldNudgeShortNearEndCompletion({
    required TargetPlatform platform,
    required Duration duration,
    required Duration remaining,
    required Duration position,
  }) {
    return platform == TargetPlatform.iOS &&
        duration > Duration.zero &&
        remaining > Duration.zero &&
        remaining <= const Duration(milliseconds: 700) &&
        position >= const Duration(milliseconds: 800);
  }

  static bool shouldRecoverFrozenShortOnStall({
    required TargetPlatform platform,
    required bool hasRenderedFirstFrame,
    required bool isCompleted,
    required int stallRetryCount,
    required Duration position,
  }) {
    return platform == TargetPlatform.iOS &&
        hasRenderedFirstFrame &&
        !isCompleted &&
        (stallRetryCount > 1 ||
            position >= const Duration(milliseconds: 2500));
  }

  static bool shouldHardRestartShortAfterStall({
    required TargetPlatform platform,
    required int stallRetryCount,
    required Duration position,
  }) {
    return platform == TargetPlatform.iOS &&
        stallRetryCount > 1 &&
        position > Duration.zero &&
        position < const Duration(milliseconds: 2000);
  }

  static Duration shortTierDebounceDelay({
    required TargetPlatform platform,
    required Duration defaultDelay,
  }) {
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return const Duration(milliseconds: 20);
    }
    return defaultDelay;
  }

  static Duration shortTierReconcileDelay({
    required TargetPlatform platform,
    required Duration defaultDelay,
  }) {
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return const Duration(milliseconds: 90);
    }
    return defaultDelay;
  }

  static Duration shortIosAudibilityReassertDelay({
    required int attempt,
  }) {
    const attemptDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 110),
      Duration(milliseconds: 260),
      Duration(milliseconds: 520),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1400),
      Duration(milliseconds: 2000),
    ];
    final safeAttempt = attempt.clamp(0, attemptDelays.length - 1);
    return attemptDelays[safeAttempt];
  }

  static Duration shortIosNativePlaybackGuardDelay({
    required int attempt,
  }) {
    return attempt == 0
        ? const Duration(milliseconds: 1400)
        : const Duration(milliseconds: 900);
  }

  static int shortStallMaxRetries({
    required TargetPlatform platform,
  }) {
    return platform == TargetPlatform.iOS ? 4 : 2;
  }
}
