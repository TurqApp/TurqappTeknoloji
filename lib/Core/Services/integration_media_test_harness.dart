import 'dart:collection';
import 'dart:io';

enum IntegrationMediaFailureKind {
  photosDenied,
  cameraDenied,
  microphoneDenied,
  pickerCancelled,
  pickerFailed,
  imageUploadFailed,
  videoUploadFailed,
  audioUploadFailed,
}

class IntegrationMediaTestHarness {
  IntegrationMediaTestHarness._();

  static final Queue<List<File>> _queuedGalleryImageSelections =
      Queue<List<File>>();
  static final Queue<File?> _queuedCameraPhotos = Queue<File?>();
  static final Queue<File?> _queuedGalleryVideos = Queue<File?>();
  static final Queue<File?> _queuedCameraCaptureResults = Queue<File?>();
  static final Queue<bool> _queuedVoicePermissions = Queue<bool>();
  static final Queue<IntegrationMediaFailureKind> _queuedFailures =
      Queue<IntegrationMediaFailureKind>();

  static bool get isActive =>
      _queuedGalleryImageSelections.isNotEmpty ||
      _queuedCameraPhotos.isNotEmpty ||
      _queuedGalleryVideos.isNotEmpty ||
      _queuedCameraCaptureResults.isNotEmpty ||
      _queuedVoicePermissions.isNotEmpty ||
      _queuedFailures.isNotEmpty;

  static void reset() {
    _queuedGalleryImageSelections.clear();
    _queuedCameraPhotos.clear();
    _queuedGalleryVideos.clear();
    _queuedCameraCaptureResults.clear();
    _queuedVoicePermissions.clear();
    _queuedFailures.clear();
  }

  static void queueGalleryImageSelection(List<File> files) {
    _queuedGalleryImageSelections.add(
      files.toList(growable: false),
    );
  }

  static void queueCameraPhoto(File? file) {
    _queuedCameraPhotos.add(file);
  }

  static void queueGalleryVideo(File? file) {
    _queuedGalleryVideos.add(file);
  }

  static void queueCameraCaptureResult(File? file) {
    _queuedCameraCaptureResults.add(file);
  }

  static void queueVoicePermission(bool granted) {
    _queuedVoicePermissions.add(granted);
  }

  static void queueFailure(IntegrationMediaFailureKind kind) {
    _queuedFailures.add(kind);
  }

  static List<File>? takeGalleryImageSelection() {
    if (_queuedGalleryImageSelections.isEmpty) return null;
    return _queuedGalleryImageSelections.removeFirst();
  }

  static File? takeCameraPhoto() {
    if (_queuedCameraPhotos.isEmpty) return null;
    return _queuedCameraPhotos.removeFirst();
  }

  static File? takeGalleryVideo() {
    if (_queuedGalleryVideos.isEmpty) return null;
    return _queuedGalleryVideos.removeFirst();
  }

  static File? takeCameraCaptureResult() {
    if (_queuedCameraCaptureResults.isEmpty) return null;
    return _queuedCameraCaptureResults.removeFirst();
  }

  static bool? takeVoicePermission() {
    if (_queuedVoicePermissions.isEmpty) return null;
    return _queuedVoicePermissions.removeFirst();
  }

  static bool consumeFailure(IntegrationMediaFailureKind kind) {
    final index = _queuedFailures.toList().indexOf(kind);
    if (index < 0) return false;
    final retained = Queue<IntegrationMediaFailureKind>.from(_queuedFailures);
    _queuedFailures
      ..clear()
      ..addAll(retained.toList()..removeAt(index));
    return true;
  }

  static Map<String, dynamic> snapshot() {
    return <String, dynamic>{
      'active': isActive,
      'galleryImageSelections': _queuedGalleryImageSelections.length,
      'cameraPhotos': _queuedCameraPhotos.length,
      'galleryVideos': _queuedGalleryVideos.length,
      'cameraCaptureResults': _queuedCameraCaptureResults.length,
      'voicePermissionDecisions': _queuedVoicePermissions.length,
      'queuedFailures': _queuedFailures.map((item) => item.name).toList(),
    };
  }
}
