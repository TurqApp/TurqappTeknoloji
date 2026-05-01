import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Core/Repositories/short_manifest_repository.dart';

class SignInEntryWarmService {
  SignInEntryWarmService._();

  static Future<void>? _inFlight;

  static Future<void> ensureStarted({
    String source = 'unknown',
  }) {
    final existing = _inFlight;
    if (existing != null) {
      debugPrint('[AuthEntryWarm] status=join_existing source=$source');
      return existing;
    }

    Future<void> runStep(
      String label,
      Future<void> Function() action,
    ) async {
      final startedAt = DateTime.now();
      debugPrint('[AuthEntryWarm] status=start label=$label source=$source');
      try {
        await action();
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=$label '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
        );
      } catch (error) {
        debugPrint(
          '[AuthEntryWarm] status=refresh_fail label=$label '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
          'error=$error',
        );
        rethrow;
      }
    }

    Future<void> runFloodStep() async {
      final startedAt = DateTime.now();
      debugPrint('[AuthEntryWarm] status=start label=flood_manifest source=$source');
      try {
        final roots = await ExploreRepository.ensure().ensureFloodManifestStoreReady();
        if (roots <= 0) {
          throw StateError('flood_manifest_empty');
        }
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=flood_manifest '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} roots=$roots',
        );
      } catch (error) {
        debugPrint(
          '[AuthEntryWarm] status=refresh_fail label=flood_manifest '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
          'error=$error',
        );
        rethrow;
      }
    }

    final future = () async {
      debugPrint('[AuthEntryWarm] status=begin source=$source');
      try {
        await runStep(
          'feed_manifest',
          () => ensureFeedManifestRepository().warmStartupWindow(),
        );
        await runStep(
          'short_manifest',
          () => ensureShortManifestRepository().warmStartupWindow(),
        );
        await runFloodStep();
      } finally {
        debugPrint('[AuthEntryWarm] status=finish source=$source');
      }
    }();

    _inFlight = future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    return _inFlight!;
  }
}
