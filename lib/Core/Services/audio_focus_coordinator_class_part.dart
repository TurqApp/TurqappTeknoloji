part of 'audio_focus_coordinator.dart';

/// Uygulama genelinde tek bir aktif ses kaynağı olmasını zorlar.
class AudioFocusCoordinator extends _AudioFocusCoordinatorBase {
  static AudioFocusCoordinator? maybeFind() =>
      _maybeFindAudioFocusCoordinator();

  static AudioFocusCoordinator ensure() => _ensureAudioFocusCoordinator();

  static AudioFocusCoordinator get instance {
    return ensure();
  }
}
