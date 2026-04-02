part of 'hls_controller.dart';

extension HLSControllerDiagnosticsPart on HLSController {
  Future<double> getCurrentTime() async {
    if (_isInactive || _viewId == null) return 0.0;

    try {
      final result = await HLSController._methodChannel
          .invokeMethod<double>('getCurrentTime', {
        'viewId': _viewId,
      });
      return result ?? 0.0;
    } on PlatformException catch (e) {
      _handleError('Failed to get current time: ${e.message}');
      return 0.0;
    }
  }

  Future<double> getDuration() async {
    if (_isInactive || _viewId == null) return 0.0;

    try {
      final result = await HLSController._methodChannel.invokeMethod<double>(
        'getDuration',
        {
          'viewId': _viewId,
        },
      );
      return result ?? 0.0;
    } on PlatformException catch (e) {
      _handleError('Failed to get duration: ${e.message}');
      return 0.0;
    }
  }

  Future<bool> isMutedNative() async {
    if (_isInactive || _viewId == null) return false;

    try {
      final result = await HLSController._methodChannel.invokeMethod<bool>(
        'isMuted',
        {
          'viewId': _viewId,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handleError('Failed to get mute state: ${e.message}');
      return false;
    }
  }

  Future<bool> isPlayingNative() async {
    if (_isInactive || _viewId == null) return false;

    try {
      final result = await HLSController._methodChannel.invokeMethod<bool>(
        'isPlaying',
        {
          'viewId': _viewId,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handleError('Failed to get play state: ${e.message}');
      return false;
    }
  }

  Future<bool> isBufferingNative() async {
    if (_isInactive || _viewId == null) return false;

    try {
      final result = await HLSController._methodChannel.invokeMethod<bool>(
        'isBuffering',
        {
          'viewId': _viewId,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handleError('Failed to get buffering state: ${e.message}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPlaybackDiagnostics() async {
    if (_isInactive || _viewId == null) return const <String, dynamic>{};

    try {
      final result = await HLSController._methodChannel.invokeMethod<dynamic>(
        'getPlaybackDiagnostics',
        {'viewId': _viewId},
      );
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return const <String, dynamic>{};
    } on PlatformException catch (e) {
      _handleError('Failed to get playback diagnostics: ${e.message}');
      return const <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> getProcessDiagnostics() async {
    if (_isInactive || _viewId == null) return const <String, dynamic>{};

    try {
      final result = await HLSController._methodChannel.invokeMethod<dynamic>(
        'getProcessDiagnostics',
        {'viewId': _viewId},
      );
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return const <String, dynamic>{};
    } on PlatformException catch (e) {
      _handleError('Failed to get process diagnostics: ${e.message}');
      return const <String, dynamic>{};
    }
  }
}
