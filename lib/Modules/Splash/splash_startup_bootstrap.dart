import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/firestore_config.dart';
import 'package:turqappv2/main.dart';

class StartupBootstrap {
  StartupBootstrap({
    required this.firebaseStartupWait,
    Future<void> Function()? waitForFirebaseBootstrap,
    Future<void> Function()? initializeFirestoreConfig,
    Future<SharedPreferences> Function()? readPreferences,
    Future<void> Function()? initializeAudioContext,
  })  : _waitForFirebaseBootstrap = waitForFirebaseBootstrap ??
            (() async {
              await firebaseBootstrapFuture.timeout(
                firebaseStartupWait,
                onTimeout: () {},
              );
            }),
        _initializeFirestoreConfig =
            initializeFirestoreConfig ?? _defaultInitializeFirestoreConfig,
        _readPreferences = readPreferences ?? SharedPreferences.getInstance,
        _initializeAudioContext =
            initializeAudioContext ?? _defaultInitializeAudioContext;

  final Duration firebaseStartupWait;
  final Future<void> Function() _waitForFirebaseBootstrap;
  final Future<void> Function() _initializeFirestoreConfig;
  final Future<SharedPreferences> Function() _readPreferences;
  final Future<void> Function() _initializeAudioContext;

  Future<SharedPreferences> run() async {
    late final SharedPreferences prefs;
    await Future.wait([
      (() async {
        await _waitForFirebaseBootstrap();
        await _initializeFirestoreConfig();
      })(),
      _readPreferences().then((value) => prefs = value),
      _initializeAudioContext().catchError((_) {}),
    ]);
    return prefs;
  }

  static Future<void> _defaultInitializeFirestoreConfig() async {
    await FirestoreConfig.initialize().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  }

  static Future<void> _defaultInitializeAudioContext() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }
}
