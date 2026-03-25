import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:turqappv2/Core/upload_constants.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Core/Services/video_compression_service.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'upload_queue_service_helpers_part.dart';
part 'upload_queue_service_models_part.dart';
part 'upload_queue_service_persistence_part.dart';
part 'upload_queue_service_post_shell_part.dart';
part 'upload_queue_service_processing_part.dart';

class UploadQueueService extends GetxController {
  static UploadQueueService? maybeFind() {
    final isRegistered = Get.isRegistered<UploadQueueService>();
    if (!isRegistered) return null;
    return Get.find<UploadQueueService>();
  }

  static UploadQueueService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UploadQueueService(), permanent: permanent);
  }

  static int get _maxVideoBytesForStorageRule =>
      UploadValidationService.currentMaxVideoSizeBytes;
  static const Duration _recentDuplicateWindow = Duration(minutes: 15);
  final RxList<QueuedUpload> _queue = <QueuedUpload>[].obs;
  final RxBool _isProcessing = false.obs;
  final RxBool _isPaused = false.obs;
  final RxInt _failedCount = 0.obs;
  final RxInt _completedCount = 0.obs;
  StreamSubscription<User?>? _authSub;

  List<QueuedUpload> get queue => _queue;
  bool get isProcessing => _isProcessing.value;
  bool get isPaused => _isPaused.value;
  int get failedCount => _failedCount.value;
  int get completedCount => _completedCount.value;
  int get pendingCount =>
      _queue.where((item) => item.status == UploadStatus.pending).length;

  static const String _queueKeyPrefix = 'upload_queue';
  static const int _maxRetries = 3;

  void _notifyQueueUpdated() {
    _queue.refresh();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeQueuePersistence();
  }

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

  /// Add upload to queue
  Future<bool> addToQueue(
    QueuedUpload upload, {
    bool startProcessing = true,
  }) async {
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
          'common.info'.tr, 'upload_queue.already_uploaded_recently'.tr);
      return false;
    }
    _queue.add(upload);
    _notifyQueueUpdated();
    await _saveQueueToStorage();
    await _createPendingPostShell(upload);
    if (startProcessing) {
      _processQueue();
    }
    return true;
  }

  void processPendingQueue() {
    _processQueue();
  }

  Future<void> _createPendingPostShell(QueuedUpload upload) =>
      _performCreatePendingPostShell(upload);

  /// Start processing queue
  void _processQueue() => _performProcessQueue();

  /// Process individual upload
  Future<void> _processUpload(QueuedUpload upload) =>
      _performProcessUpload(upload);

  /// Pause queue processing
  void pauseQueue() => _performPauseQueue();

  /// Resume queue processing
  void resumeQueue() => _performResumeQueue();

  /// Clear completed uploads
  void clearCompleted() => _performClearCompleted();

  /// Retry failed uploads
  void retryFailed() => _performRetryFailed();

  /// Remove upload from queue
  void removeUpload(String uploadId) => _performRemoveUpload(uploadId);

  /// Save queue to local storage
  Future<void> _saveQueueToStorage() => _performSaveQueueToStorage();

  /// Load queue from local storage
  Future<void> _loadQueueFromStorage() => _performLoadQueueFromStorage();

  /// Listen to connectivity changes
  void _listenToConnectivity() => _performListenToConnectivity();

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() => _performGetQueueStats();

  @override
  void onClose() {
    _disposeQueuePersistence();
    super.onClose();
  }
}
