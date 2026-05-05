part of 'upload_queue_service.dart';

extension UploadQueueServiceQueuePart on UploadQueueService {
  String get _queueKey {
    return userScopedKey(_queueKeyPrefix);
  }

  String _queueFingerprintForMap(Map<String, dynamic> data) {
    final sourceImages = (data['sourceImagePaths'] is List)
        ? List<String>.from(data['sourceImagePaths'] as List)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    sourceImages.sort();
    final sourceVideo = (data['sourceVideoPath'] ?? '').toString().trim();
    final text = (data['text'] ?? '').toString().trim();
    final location = (data['location'] ?? '').toString().trim();
    final gif = (data['gif'] ?? '').toString().trim();
    final userID = (data['userID'] ?? '').toString().trim();
    final scheduledAt = (data['scheduledAt'] ?? 0).toString();
    return jsonEncode({
      'userID': userID,
      'text': text,
      'location': location,
      'gif': gif,
      'scheduledAt': scheduledAt,
      'sourceImagePaths': sourceImages,
      'sourceVideoPath': sourceVideo,
    });
  }

  String _queueFingerprint(QueuedUpload upload) {
    try {
      final map = jsonDecode(upload.postData) as Map<String, dynamic>;
      return _queueFingerprintForMap(map);
    } catch (_) {
      return '';
    }
  }

  String _seriesBaseId(String id) {
    final splitAt = id.lastIndexOf('_');
    if (splitAt <= 0) return id;
    return id.substring(0, splitAt);
  }

  int _parseIntValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? fallback;
  }

  Future<String> _resolveQuoteCounterTargetPostId({
    required String sourcePostId,
    required String originalPostId,
  }) async {
    final candidate = sourcePostId.trim().isNotEmpty
        ? sourcePostId.trim()
        : originalPostId.trim();
    if (candidate.isEmpty) return '';

    final raw = await PostRepository.ensure().fetchPostRawById(
          candidate,
          preferCache: true,
        ) ??
        const <String, dynamic>{};
    if (raw.isEmpty) return candidate;

    final floodCount = _parseIntValue(raw['floodCount']);
    if (floodCount <= 1) return candidate;

    final mainFlood = (raw['mainFlood'] ?? '').toString().trim();
    final isFlood = raw['flood'] == true;
    if (isFlood && mainFlood.isNotEmpty) {
      return mainFlood;
    }
    return candidate;
  }

  Future<bool> addToQueue(
    QueuedUpload upload, {
    bool startProcessing = true,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[UploadQueue][Add] start id=${upload.id} '
        'images=${upload.imagePaths.length} '
        'hasVideo=${(upload.videoPath ?? '').trim().isNotEmpty} '
        'startProcessing=$startProcessing',
      );
    }
    final fingerprint = _queueFingerprint(upload);
    final baseId = _seriesBaseId(upload.id);
    final duplicateActive = fingerprint.isNotEmpty &&
        _queue.any((item) =>
            _seriesBaseId(item.id) != baseId &&
            item.status != UploadStatus.completed &&
            item.status != UploadStatus.failed &&
            _queueFingerprint(item) == fingerprint);
    if (duplicateActive) {
      AppSnackbar('common.info'.tr, 'upload_queue.already_uploading'.tr);
      return false;
    }
    final recentDuplicate = fingerprint.isNotEmpty &&
        _queue.any((item) =>
            _seriesBaseId(item.id) != baseId &&
            item.status == UploadStatus.completed &&
            DateTime.now().difference(item.createdAt) <=
                _recentDuplicateWindow &&
            _queueFingerprint(item) == fingerprint);
    if (recentDuplicate) {
      AppSnackbar(
        'common.info'.tr,
        'upload_queue.already_uploaded_recently'.tr,
      );
      return false;
    }
    try {
      _queue.add(upload);
      _notifyQueueUpdated();
      if (kDebugMode) {
        debugPrint('[UploadQueue][Add] queue_appended id=${upload.id}');
      }
      await _saveQueueToStorage();
      if (kDebugMode) {
        debugPrint('[UploadQueue][Add] queue_saved id=${upload.id}');
      }
      await _createPendingPostShell(upload);
      if (kDebugMode) {
        debugPrint('[UploadQueue][Add] shell_created id=${upload.id}');
      }
      if (startProcessing) {
        if (kDebugMode) {
          debugPrint('[UploadQueue][Add] process_queue id=${upload.id}');
        }
        _processQueue();
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[UploadQueue][Add] failed id=${upload.id} '
          'error=$e stack=$stackTrace',
        );
      }
      rethrow;
    }
  }

  void processPendingQueue() {
    _processQueue();
  }
}
