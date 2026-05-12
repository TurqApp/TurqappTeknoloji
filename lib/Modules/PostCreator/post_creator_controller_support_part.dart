part of 'post_creator_controller.dart';

Future<int> _resolveMaxVideoBytesForStorageRule() =>
    UploadValidationService.currentMaxVideoSizeBytesAsync();
const int _maxScheduledWindowDays = 90;
int _lastModerationSnackbarAtMs = 0;

final PostRepository _postRepository = PostRepository.ensure();
final ProfileRepository _profileRepository = ensureProfileRepository();
final ProfilePostsSnapshotRepository _profileSnapshotRepository =
    ProfilePostsSnapshotRepository.ensure();
final agendaController = ensureAgendaController();
final ErrorHandlingService _errorService = ensureErrorHandlingService();
const NetworkRuntimeService _networkRuntimeService = NetworkRuntimeService();
const UploadQueueRuntimeService _uploadQueueRuntimeService =
    UploadQueueRuntimeService();
final DraftService _draftService = ensureDraftService();

String get _currentUid => CurrentUserService.instance.effectiveUserId;

class _GeneratedThumbnailResult {
  const _GeneratedThumbnailResult({
    required this.bytes,
    required this.strategy,
    this.frameMs,
    required this.version,
  });

  final Uint8List? bytes;
  final String strategy;
  final int? frameMs;
  final int version;
}

extension PostCreatorControllerSupportPart on PostCreatorController {
  DateTime get maxIzBirakDate =>
      DateTime.now().add(const Duration(days: _maxScheduledWindowDays));

  static const List<int> _standardThumbnailCandidateMs = <int>[
    0,
    33,
    67,
    100,
  ];

  Future<_GeneratedThumbnailResult> generateStandardThumbnail(
    File videoFile,
  ) async {
    Uint8List? bestData;
    int? bestMs;
    double bestScore = double.negativeInfinity;

    for (final ms in _standardThumbnailCandidateMs) {
      final data = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: ms,
        maxWidth: UploadConstants.thumbnailMaxWidth,
        quality: 75,
      );
      if (data == null || data.isEmpty) continue;
      final score = await _thumbnailQualityScore(data);
      if (score != null && score >= 18) {
        return _GeneratedThumbnailResult(
          bytes: data,
          strategy: 'auto_early_frame',
          frameMs: ms,
          version: 2,
        );
      }
      if (score != null && score > bestScore) {
        bestScore = score;
        bestData = data;
        bestMs = ms;
      } else {
        bestData ??= data;
        bestMs ??= ms;
      }
    }

    return _GeneratedThumbnailResult(
      bytes: bestData,
      strategy: 'auto_early_frame',
      frameMs: bestMs,
      version: 2,
    );
  }

  Future<double?> _thumbnailQualityScore(Uint8List data) async {
    try {
      final codec = await ui.instantiateImageCodec(
        data,
        targetWidth: 24,
        targetHeight: 24,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) return null;

      double sum = 0;
      double sumSquares = 0;
      int count = 0;

      for (int i = 0; i + 3 < bytes.length; i += 4) {
        final r = bytes[i].toDouble();
        final g = bytes[i + 1].toDouble();
        final b = bytes[i + 2].toDouble();
        final luma = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
        sum += luma;
        sumSquares += luma * luma;
        count++;
      }

      if (count == 0) return null;
      final mean = sum / count;
      final variance = (sumSquares / count) - (mean * mean);
      if (mean < 14) return mean - 1000;
      return variance + (mean * 0.15);
    } catch (_) {
      return null;
    }
  }

  Future<void> prepareForRoute({
    required String routeId,
    required bool sharedAsPost,
    required bool editMode,
  }) =>
      _PostCreatorControllerRouteX(this)._prepareForRoute(
        routeId: routeId,
        sharedAsPost: sharedAsPost,
        editMode: editMode,
      );

  Future<void> resetComposerState() =>
      _PostCreatorControllerRouteX(this)._resetComposerState();

  void uploadAllPostsInBackground() =>
      _PostCreatorControllerUiX(this)._uploadAllPostsInBackground();

  Future<void> showCommentOptions() =>
      _PostCreatorControllerUiX(this)._showCommentOptions();

  Future<void> persistUploadedPostsToHomeFeed(
    List<PostsModel> posts,
  ) async {
    final normalizedPosts = posts
        .where((post) => post.docID.trim().isNotEmpty)
        .toList(growable: false);
    if (normalizedPosts.isEmpty) return;

    final userId = _currentUid.trim();
    if (userId.isEmpty) return;

    final repository = ensureFeedSnapshotRepository();
    final snapshot = await repository.bootstrapHome(
      userId: userId,
      limit: 40,
    );
    final merged = <String, PostsModel>{
      for (final post in normalizedPosts) post.docID: post,
    };
    for (final existing in snapshot.data ?? const <PostsModel>[]) {
      merged.putIfAbsent(existing.docID, () => existing);
    }

    final ordered = merged.values.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await repository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: 40,
      source: CachedResourceSource.memory,
    );
  }
}
