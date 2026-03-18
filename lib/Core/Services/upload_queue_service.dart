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
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/video_compression_service.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

enum UploadStatus {
  pending('Bekliyor'),
  uploading('Yükleniyor'),
  completed('Tamamlandı'),
  failed('Başarısız'),
  paused('Duraklatıldı');

  const UploadStatus(this.label);
  final String label;
}

class QueuedUpload {
  final String id;
  final String postData;
  final List<String> imagePaths;
  final String? videoPath;
  final DateTime createdAt;
  UploadStatus status;
  int retryCount;
  String? errorMessage;
  double progress;

  QueuedUpload({
    required this.id,
    required this.postData,
    required this.imagePaths,
    this.videoPath,
    required this.createdAt,
    this.status = UploadStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postData': postData,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
        'createdDate': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'progress': progress,
      };

  factory QueuedUpload.fromJson(Map<String, dynamic> json) => QueuedUpload(
        id: json['id'],
        postData: json['postData'],
        imagePaths: List<String>.from(json['imagePaths']),
        videoPath: json['videoPath'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
        status: UploadStatus.values.firstWhere((e) => e.name == json['status']),
        retryCount: json['retryCount'] ?? 0,
        errorMessage: json['errorMessage'],
        progress: json['progress']?.toDouble() ?? 0.0,
      );
}

class UploadQueueService extends GetxController {
  static const int _maxVideoBytesForStorageRule = 35 * 1024 * 1024;
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

  String _normalizeHandleValue(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return '';
    if (value.contains(RegExp(r'\s'))) return '';
    return value.replaceFirst(RegExp(r'^@+'), '');
  }

  String _firstNonEmptyValue(Iterable<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _isAuthRetryableStorageError(FirebaseException e) {
    final code = e.code.toLowerCase();
    return code == 'unauthenticated' || code == 'unauthorized';
  }

  Future<void> _refreshAuthTokenIfNeeded() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Best effort only.
    }
  }

  Future<TaskSnapshot> _putFileWithAuthRetry({
    required Reference ref,
    required File file,
    required SettableMetadata metadata,
  }) async {
    try {
      return await ref.putFile(file, metadata);
    } on FirebaseException catch (e) {
      if (!_isAuthRetryableStorageError(e)) rethrow;
      await _refreshAuthTokenIfNeeded();
      return await ref.putFile(file, metadata);
    }
  }

  void _notifyQueueUpdated() {
    _queue.refresh();
  }

  @override
  void onInit() {
    super.onInit();
    _loadQueueFromStorage();
    _listenToConnectivity();
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_loadQueueFromStorage());
    });
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
      AppSnackbar('Bilgi', 'Bu medya zaten yükleniyor.');
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
      AppSnackbar('Bilgi', 'Bu medya kısa süre önce zaten yüklendi.');
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

  Future<void> _createPendingPostShell(QueuedUpload upload) async {
    final postDataMap = jsonDecode(upload.postData) as Map<String, dynamic>;
    final String userID =
        (FirebaseAuth.instance.currentUser?.uid ?? postDataMap['userID'] ?? '')
            .toString()
            .trim();
    if (userID.isEmpty) return;

    final String text = (postDataMap['text'] ?? '')
        .toString()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
    final String location = (postDataMap['location'] ?? '').toString().trim();
    final Map<String, dynamic> yorumMap =
        Map<String, dynamic>.from(postDataMap['yorumMap'] ?? {});
    final Map<String, dynamic> reshareMap =
        Map<String, dynamic>.from(postDataMap['reshareMap'] ?? {});
    final Map<String, dynamic> poll =
        Map<String, dynamic>.from(postDataMap['poll'] ?? {});
    final bool sharedAsPost = (postDataMap['sharedAsPost'] ?? false) == true;
    final String originalUserID =
        (postDataMap['originalUserID'] ?? '').toString().trim();
    final String originalPostID =
        (postDataMap['originalPostID'] ?? '').toString().trim();
    final String sourcePostID =
        (postDataMap['sourcePostID'] ?? '').toString().trim();
    final bool quotedPost = (postDataMap['quotedPost'] ?? false) == true;
    final String quotedOriginalText =
        (postDataMap['quotedOriginalText'] ?? '').toString().trim();
    final String quotedSourceUserID =
        (postDataMap['quotedSourceUserID'] ?? '').toString().trim();
    final String quotedSourceDisplayName =
        (postDataMap['quotedSourceDisplayName'] ?? '').toString().trim();
    final String quotedSourceUsername =
        (postDataMap['quotedSourceUsername'] ?? '').toString().trim();
    final String quotedSourceAvatarUrl =
        (postDataMap['quotedSourceAvatarUrl'] ?? '').toString().trim();
    final currentUser = CurrentUserService.instance;
    final String authorNickname = _firstNonEmptyValue([
      _normalizeHandleValue(postDataMap['nickname']),
      _normalizeHandleValue(postDataMap['authorNickname']),
      _normalizeHandleValue(currentUser.nickname),
    ]);
    final String username = _firstNonEmptyValue([
      _normalizeHandleValue(postDataMap['username']),
    ]);
    final String fullName = _firstNonEmptyValue([
      postDataMap['fullName'],
      postDataMap['authorDisplayName'],
      postDataMap['displayName'],
      currentUser.fullName,
      authorNickname,
    ]);
    final String authorDisplayName = _firstNonEmptyValue([
      postDataMap['authorDisplayName'],
      postDataMap['displayName'],
      fullName,
      authorNickname,
    ]);
    final String authorAvatarUrl =
        (postDataMap['authorAvatarUrl'] ?? currentUser.avatarUrl)
            .toString()
            .trim();
    final String authorRozet = _firstNonEmptyValue([
      postDataMap['rozet'],
      currentUser.currentUser?.rozet.trim() ?? '',
    ]);
    final int scheduledAt =
        int.tryParse('${postDataMap['scheduledAt'] ?? 0}') ?? 0;

    bool flood = false;
    String mainFlood = '';
    try {
      final idxStr = upload.id.substring(upload.id.lastIndexOf('_') + 1);
      final idx = int.tryParse(idxStr) ?? 0;
      flood = idx != 0;
      if (flood) {
        final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
        mainFlood = '${base}_0';
      }
    } catch (_) {}

    int floodCount = 1;
    try {
      final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
      floodCount = _queue.where((q) => q.id.startsWith('${base}_')).length;
      if (floodCount <= 0) floodCount = 1;
    } catch (_) {}

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final publishTime = scheduledAt != 0 ? scheduledAt : nowMs;

    await FirebaseFirestore.instance.collection('Posts').doc(upload.id).set({
      "arsiv": true,
      "debugMode": false,
      "deletedPost": false,
      "deletedPostTime": 0,
      "flood": flood,
      "floodCount": floodCount,
      "gizlendi": false,
      "img": const <String>[],
      "imgMap": const <Map<String, dynamic>>[],
      "isAd": false,
      "ad": false,
      "izBirakYayinTarihi": publishTime,
      "konum": location,
      "mainFlood": mainFlood,
      "metin": text,
      "scheduledAt": scheduledAt,
      "sikayetEdildi": false,
      "stabilized": false,
      "stats": {
        "commentCount": 0,
        "likeCount": 0,
        "reportedCount": 0,
        "retryCount": 0,
        "savedCount": 0,
        "statsCount": 0
      },
      "tags": const <String>[],
      "thumbnail": "",
      "timeStamp": nowMs,
      "userID": userID,
      "authorNickname": authorNickname,
      "authorDisplayName": authorDisplayName,
      "authorAvatarUrl": authorAvatarUrl,
      "nickname": authorNickname,
      "username": username,
      "fullName": fullName,
      "displayName": authorDisplayName,
      "avatarUrl": authorAvatarUrl,
      "rozet": authorRozet,
      "video": "",
      "isUploading": true,
      "yorumMap": yorumMap,
      "reshareMap": reshareMap,
      if (poll.isNotEmpty) "poll": poll,
      "originalUserID": sharedAsPost ? originalUserID : "",
      "originalPostID": sharedAsPost ? originalPostID : "",
      "sourcePostID": sharedAsPost ? sourcePostID : "",
      "sharedAsPost": sharedAsPost,
      "quotedPost": sharedAsPost ? quotedPost : false,
      "quotedOriginalText":
          (sharedAsPost && quotedPost) ? quotedOriginalText : "",
      "quotedSourceUserID":
          (sharedAsPost && quotedPost) ? quotedSourceUserID : "",
      "quotedSourceDisplayName":
          (sharedAsPost && quotedPost) ? quotedSourceDisplayName : "",
      "quotedSourceUsername":
          (sharedAsPost && quotedPost) ? quotedSourceUsername : "",
      "quotedSourceAvatarUrl":
          (sharedAsPost && quotedPost) ? quotedSourceAvatarUrl : "",
    }, SetOptions(merge: true));
  }

  /// Start processing queue
  void _processQueue() async {
    if (_isProcessing.value || _isPaused.value) return;

    _isProcessing.value = true;

    while (_queue.any((item) => item.status == UploadStatus.pending) &&
        !_isPaused.value) {
      final nextUpload = _queue.firstWhere(
        (item) => item.status == UploadStatus.pending,
        orElse: () => _queue.first,
      );

      if (nextUpload.status == UploadStatus.pending) {
        await _processUpload(nextUpload);
      }
    }

    _isProcessing.value = false;
  }

  /// Process individual upload
  Future<void> _processUpload(QueuedUpload upload) async {
    try {
      // Check network connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork =
          connectivity.any((result) => result != ConnectivityResult.none);
      if (!hasNetwork) {
        upload.status = UploadStatus.failed;
        upload.errorMessage = 'İnternet bağlantısı yok';
        await _saveQueueToStorage();
        AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
        return;
      }

      upload.status = UploadStatus.uploading;
      upload.progress = 0.0;
      _notifyQueueUpdated();
      await _saveQueueToStorage();

      final postDataMap = jsonDecode(upload.postData);
      final String text = (postDataMap['text'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
          .trim();
      final String location = (postDataMap['location'] ?? '').toString();
      final String gif = (postDataMap['gif'] ?? '').toString();
      // Always bind queued uploads to current session user.
      // Stale queue payload may contain old userID and fail Storage isPostOwner rule.
      String userID = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userID.trim().isEmpty) {
        throw Exception('userID boş: upload sırasında oturum bulunamadı');
      }
      final Map<String, dynamic> yorumMap =
          Map<String, dynamic>.from(postDataMap['yorumMap'] ?? {});
      final Map<String, dynamic> reshareMap =
          Map<String, dynamic>.from(postDataMap['reshareMap'] ?? {});
      final Map<String, dynamic> poll =
          Map<String, dynamic>.from(postDataMap['poll'] ?? {});
      final bool sharedAsPost = (postDataMap['sharedAsPost'] ?? false) == true;
      final String originalUserID =
          (postDataMap['originalUserID'] ?? '').toString().trim();
      final String originalPostID =
          (postDataMap['originalPostID'] ?? '').toString().trim();
      final String sourcePostID =
          (postDataMap['sourcePostID'] ?? '').toString().trim();
      final bool quotedPost = (postDataMap['quotedPost'] ?? false) == true;
      final String quotedOriginalText =
          (postDataMap['quotedOriginalText'] ?? '').toString().trim();
      final String quotedSourceUserID =
          (postDataMap['quotedSourceUserID'] ?? '').toString().trim();
      final String quotedSourceDisplayName =
          (postDataMap['quotedSourceDisplayName'] ?? '').toString().trim();
      final String quotedSourceUsername =
          (postDataMap['quotedSourceUsername'] ?? '').toString().trim();
      final String quotedSourceAvatarUrl =
          (postDataMap['quotedSourceAvatarUrl'] ?? '').toString().trim();
      final currentUser = CurrentUserService.instance;
      final String authorNickname = _firstNonEmptyValue([
        _normalizeHandleValue(postDataMap['nickname']),
        _normalizeHandleValue(postDataMap['authorNickname']),
        _normalizeHandleValue(currentUser.nickname),
      ]);
      final String username = _firstNonEmptyValue([
        _normalizeHandleValue(postDataMap['username']),
      ]);
      final String fullName = _firstNonEmptyValue([
        postDataMap['fullName'],
        postDataMap['authorDisplayName'],
        postDataMap['displayName'],
        currentUser.fullName,
        authorNickname,
      ]);
      final String authorDisplayName = _firstNonEmptyValue([
        postDataMap['authorDisplayName'],
        postDataMap['displayName'],
        fullName,
        authorNickname,
      ]);
      final String authorAvatarUrl =
          (postDataMap['authorAvatarUrl'] ?? currentUser.avatarUrl)
              .toString()
              .trim();
      final String authorRozet = _firstNonEmptyValue([
        postDataMap['rozet'],
        currentUser.currentUser?.rozet.trim() ?? '',
      ]);
      if (yorumMap.isEmpty) {
        final bool comment = (postDataMap['comment'] ?? true) == true;
        yorumMap['visibility'] = comment ? 0 : 3;
      }
      if (reshareMap.isEmpty) {
        final int paylasGizliligi =
            int.tryParse('${postDataMap['paylasGizliligi'] ?? 0}') ?? 0;
        reshareMap['visibility'] = paylasGizliligi;
      }
      final int scheduledAt =
          int.tryParse('${postDataMap['scheduledAt'] ?? 0}') ?? 0;

      bool flood = false;
      String mainFlood = '';
      try {
        final idxStr = upload.id.substring(upload.id.lastIndexOf('_') + 1);
        final idx = int.tryParse(idxStr) ?? 0;
        flood = idx != 0;
        if (flood) {
          final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
          mainFlood = '${base}_0';
        }
      } catch (_) {}

      int floodCount = 1;
      try {
        final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
        floodCount = _queue.where((q) => q.id.startsWith('${base}_')).length;
        if (floodCount <= 0) floodCount = 1;
      } catch (_) {}

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final publishTime = scheduledAt != 0 ? scheduledAt : nowMs;

      // NSFW gate must run before any Firestore shell doc is created.
      for (final imagePath in upload.imagePaths) {
        final file = File(imagePath);
        if (!await file.exists()) continue;
        final nsfwImage = await OptimizedNSFWService.checkImage(file);
        if (nsfwImage.errorMessage != null) {
          upload.status = UploadStatus.failed;
          upload.errorMessage = 'NSFW görsel kontrolü başarısız';
          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(upload.id)
              .delete()
              .catchError((_) {});
          await _saveQueueToStorage();
          AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
          return;
        }
        if (nsfwImage.isNSFW) {
          upload.status = UploadStatus.failed;
          upload.errorMessage = 'Uygunsuz görsel tespit edildi';
          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(upload.id)
              .delete()
              .catchError((_) {});
          await _saveQueueToStorage();
          AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
          return;
        }
      }

      File? checkedVideoFile;
      if (upload.videoPath != null) {
        final rawVideoFile = File(upload.videoPath!);
        if (await rawVideoFile.exists()) {
          checkedVideoFile = rawVideoFile;
          try {
            checkedVideoFile = await VideoCompressionService.compressForNetwork(
              rawVideoFile,
              targetMbps: 5.0,
            );
          } catch (_) {}
          final effectiveVideoFile = checkedVideoFile ?? rawVideoFile;

          final videoSize = await effectiveVideoFile.length();
          if (videoSize > _maxVideoBytesForStorageRule) {
            upload.status = UploadStatus.failed;
            upload.errorMessage =
                'Video 35MB altına indirilemedi. 35MB altı direkt, 60MB üstü desteklenmez.';
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
            return;
          }

          final nsfwVideo =
              await OptimizedNSFWService.checkVideo(effectiveVideoFile);
          if (kDebugMode) {
            debugPrint('[NSFW][Queue][Video] '
                'blocked=${nsfwVideo.isNSFW} '
                'frames=${nsfwVideo.framesChecked} '
                'confidence=${nsfwVideo.confidence.toStringAsFixed(3)} '
                'error=${nsfwVideo.errorMessage}');
            for (final sample in nsfwVideo.debugSamples.take(80)) {
              debugPrint('[NSFW][Queue][Video][Frame] $sample');
            }
          }
          if (nsfwVideo.errorMessage != null) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'NSFW video kontrolü başarısız';
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
            return;
          }
          if (nsfwVideo.isNSFW) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'Uygunsuz video tespit edildi';
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
            return;
          }
        }
      }

      // Video/HLS pipeline starts from Storage; create the Firestore shell only
      // after local moderation gates are passed.
      await FirebaseFirestore.instance.collection('Posts').doc(upload.id).set({
        "arsiv": true,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": flood,
        "floodCount": floodCount,
        "gizlendi": false,
        "img": const <String>[],
        "imgMap": const <Map<String, dynamic>>[],
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": publishTime,
        "konum": location,
        "mainFlood": mainFlood,
        "metin": text,
        "scheduledAt": scheduledAt,
        "sikayetEdildi": false,
        "stabilized": false,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "tags": const <String>[],
        "thumbnail": "",
        "timeStamp": nowMs,
        "userID": userID,
        "authorNickname": authorNickname,
        "authorDisplayName": authorDisplayName,
        "authorAvatarUrl": authorAvatarUrl,
        "nickname": authorNickname,
        "username": username,
        "fullName": fullName,
        "displayName": authorDisplayName,
        "avatarUrl": authorAvatarUrl,
        "rozet": authorRozet,
        "video": "",
        "isUploading": true,
        "yorumMap": yorumMap,
        "reshareMap": reshareMap,
        if (poll.isNotEmpty) "poll": poll,
        "originalUserID": sharedAsPost ? originalUserID : "",
        "originalPostID": sharedAsPost ? originalPostID : "",
        "sourcePostID": sharedAsPost ? sourcePostID : "",
        "sharedAsPost": sharedAsPost,
        "quotedPost": sharedAsPost ? quotedPost : false,
        "quotedOriginalText":
            (sharedAsPost && quotedPost) ? quotedOriginalText : "",
        "quotedSourceUserID":
            (sharedAsPost && quotedPost) ? quotedSourceUserID : "",
        "quotedSourceDisplayName":
            (sharedAsPost && quotedPost) ? quotedSourceDisplayName : "",
        "quotedSourceUsername":
            (sharedAsPost && quotedPost) ? quotedSourceUsername : "",
        "quotedSourceAvatarUrl":
            (sharedAsPost && quotedPost) ? quotedSourceAvatarUrl : "",
      }, SetOptions(merge: true));

      // Upload images first (preserve extension; prefer .webp)
      final imageUrls = <String>[];
      for (int i = 0; i < upload.imagePaths.length; i++) {
        final imagePath = upload.imagePaths[i];
        final file = File(imagePath);

        if (await file.exists()) {
          final nsfwImage = await OptimizedNSFWService.checkImage(file);
          if (nsfwImage.errorMessage != null) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'NSFW görsel kontrolü başarısız';
            await _saveQueueToStorage();
            AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
            return;
          }
          if (nsfwImage.isNSFW) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'Uygunsuz görsel tespit edildi';
            await _saveQueueToStorage();
            AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
            return;
          }
          final localBytes = await file.readAsBytes();
          final url = await WebpUploadService.uploadBytesAsWebp(
            storage: FirebaseStorage.instance,
            bytes: localBytes,
            storagePathWithoutExt: 'Posts/${upload.id}/image_$i',
            maxWidth: 600,
            maxHeight: 600,
          );
          upload.progress = ((i + 1) / upload.imagePaths.length) * 0.8;
          _notifyQueueUpdated();
          if (kDebugMode) {
            final len = await file.length();
            debugPrint('[Queue] Image uploaded successfully '
                'localSize=${(len / 1e6).toStringAsFixed(2)} MB');
          }
          imageUrls.add(CdnUrlBuilder.toCdnUrl(url));
        }
      }

      // Upload video if exists
      String videoUrl = '';
      String thumbnailUrl = '';
      int thumbWidth = 0;
      int thumbHeight = 0;
      if (upload.videoPath != null) {
        File videoFile = checkedVideoFile ?? File(upload.videoPath!);
        if (await videoFile.exists()) {
          final ref = FirebaseStorage.instance.ref().child(
                'Posts/${upload.id}/video.mp4',
              );
          if (kDebugMode) {
            final postDoc = await FirebaseFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .get();
            debugPrint('[UploadPreflight][Queue] '
                'postExists=${postDoc.exists}');
          }

          final uploadTaskFuture = _putFileWithAuthRetry(
            ref: ref,
            file: videoFile,
            metadata: SettableMetadata(
              contentType: 'video/mp4',
              cacheControl: 'public, max-age=31536000, immutable',
              customMetadata: {
                'uploaderUid': userID,
              },
            ),
          );
          final uploadTask = await uploadTaskFuture;
          videoUrl = CdnUrlBuilder.toCdnUrl(
            await uploadTask.ref.getDownloadURL(),
          );
          if (kDebugMode) {
            final len = await videoFile.length();
            debugPrint('[Queue] Video uploaded successfully '
                'size=${(len / 1e6).toStringAsFixed(2)} MB');
          }

          // Generate and upload thumbnail
          final tData = await VideoThumbnail.thumbnailData(
            video: videoFile.path,
            imageFormat: ImageFormat.JPEG,
            quality: 75,
          );
          if (tData != null) {
            // Convert to WebP
            Uint8List thumbData;
            try {
              thumbData = await FlutterImageCompress.compressWithList(
                tData,
                quality: 80,
                format: CompressFormat.webp,
                minWidth: UploadConstants.thumbnailMaxWidth,
              );
            } catch (_) {
              thumbData = tData;
            }
            final tUrl = await WebpUploadService.uploadBytesAsWebp(
              storage: FirebaseStorage.instance,
              bytes: thumbData,
              storagePathWithoutExt: 'Posts/${upload.id}/thumbnail',
            );
            thumbnailUrl = CdnUrlBuilder.toCdnUrl(tUrl);
            if (kDebugMode) {
              debugPrint('[Queue] Thumbnail uploaded: '
                  'orig=${(tData.length / 1e6).toStringAsFixed(2)} MB '
                  'webp=${(thumbData.length / 1e6).toStringAsFixed(2)} MB '
                  'minWidth=${UploadConstants.thumbnailMaxWidth}');
            }

            // Compute dimensions from JPEG bytes
            final im = img.decodeImage(tData);
            if (im != null) {
              thumbWidth = im.width;
              thumbHeight = im.height;
            }
          }
        }
      }

      // Save to Firestore (full document structure)
      upload.progress = 0.95;
      _notifyQueueUpdated();

      if (gif.isNotEmpty) {
        imageUrls.add(gif);
      }

      // Aspect ratio
      double aspectRatio = 1.0;
      if (videoUrl.isNotEmpty && thumbWidth > 0 && thumbHeight > 0) {
        aspectRatio = thumbWidth / thumbHeight;
      } else if (imageUrls.length == 1 && upload.imagePaths.isNotEmpty) {
        try {
          final firstLocal = File(upload.imagePaths.first);
          if (await firstLocal.exists()) {
            final bytes = await firstLocal.readAsBytes();
            final im = img.decodeImage(bytes);
            if (im != null) {
              aspectRatio = im.width / im.height;
            }
          }
        } catch (_) {}
      } else {
        aspectRatio = imageUrls.length <= 1 ? 4.0 / 5.0 : 1.0;
      }
      aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
      final isImagePost = imageUrls.isNotEmpty && videoUrl.isEmpty;
      final List<Map<String, dynamic>> imgMap = [];
      for (int i = 0; i < imageUrls.length; i++) {
        double itemAspect = 1.0;
        try {
          if (i < upload.imagePaths.length) {
            final local = File(upload.imagePaths[i]);
            if (await local.exists()) {
              final bytes = await local.readAsBytes();
              final im = img.decodeImage(bytes);
              if (im != null && im.height > 0) {
                itemAspect = im.width / im.height;
              }
            }
          }
        } catch (_) {}
        imgMap.add({
          "url": imageUrls[i],
          "aspectRatio": double.parse(itemAspect.toStringAsFixed(4)),
        });
      }

      // Tags from text (for root post)
      final tagExp = RegExp(r"#([\p{L}\p{N}_]+)", unicode: true);
      final allTags = tagExp
          .allMatches(text)
          .map((e) => e.group(1)!.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final data = {
        "arsiv": false,
        if (!isImagePost) "aspectRatio": aspectRatio,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": flood,
        "floodCount": floodCount,
        "gizlendi": false,
        "img": imageUrls,
        "imgMap": imgMap,
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": publishTime,
        "konum": location,
        "mainFlood": mainFlood,
        "metin": text,
        "scheduledAt": scheduledAt,
        "sikayetEdildi": false,
        "stabilized": false,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "tags": flood ? [] : allTags,
        "thumbnail": thumbnailUrl,
        "timeStamp": nowMs,
        "userID": userID,
        "video": videoUrl,
        "isUploading": false,
        "yorumMap": yorumMap,
        "reshareMap": reshareMap,
        if (poll.isNotEmpty) "poll": poll,
        // Schema: always include original attribution fields
        "originalUserID": sharedAsPost ? originalUserID : "",
        "originalPostID": sharedAsPost ? originalPostID : "",
        "sourcePostID": sharedAsPost ? sourcePostID : "",
        "sharedAsPost": sharedAsPost,
        "quotedPost": sharedAsPost ? quotedPost : false,
        "quotedOriginalText":
            (sharedAsPost && quotedPost) ? quotedOriginalText : "",
        "quotedSourceUserID":
            (sharedAsPost && quotedPost) ? quotedSourceUserID : "",
        "quotedSourceDisplayName":
            (sharedAsPost && quotedPost) ? quotedSourceDisplayName : "",
        "quotedSourceUsername":
            (sharedAsPost && quotedPost) ? quotedSourceUsername : "",
        "quotedSourceAvatarUrl":
            (sharedAsPost && quotedPost) ? quotedSourceAvatarUrl : "",
      };

      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(upload.id)
          .set(data, SetOptions(merge: true));
      PostRepository.ensure().mergeCachedPostData(upload.id, data);
      unawaited(
        TypesensePostService.instance
            .syncPostById(upload.id)
            .catchError((_) {}),
      );

      if (sharedAsPost &&
          originalUserID.isNotEmpty &&
          originalPostID.isNotEmpty) {
        try {
          final shareTimestamp = DateTime.now().millisecondsSinceEpoch;
          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(originalPostID)
              .collection('postSharers')
              .doc(userID)
              .set({
            'userID': userID,
            'timestamp': shareTimestamp,
            'sharedPostID': upload.id,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // Mark as completed
      upload.status = UploadStatus.completed;
      upload.progress = 1.0;
      _completedCount.value++;
      _notifyQueueUpdated();

      await _saveQueueToStorage();
    } catch (e) {
      upload.retryCount++;

      if (upload.retryCount >= _maxRetries) {
        upload.status = UploadStatus.failed;
        upload.errorMessage = e.toString();
        _failedCount.value++;
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(upload.id)
            .delete()
            .catchError((_) {});
        AppSnackbar('Yükleme Başarısız', upload.errorMessage!);
      } else {
        upload.status = UploadStatus.pending;
        upload.errorMessage =
            'Retry ${upload.retryCount}/$_maxRetries: ${e.toString()}';

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: upload.retryCount * 2));
      }

      await _saveQueueToStorage();
      _notifyQueueUpdated();
    }
  }

  /// Pause queue processing
  void pauseQueue() {
    _isPaused.value = true;
    _notifyQueueUpdated();
  }

  /// Resume queue processing
  void resumeQueue() {
    _isPaused.value = false;
    _processQueue();
    _notifyQueueUpdated();
  }

  /// Clear completed uploads
  void clearCompleted() async {
    _queue.removeWhere((item) => item.status == UploadStatus.completed);
    _notifyQueueUpdated();
    await _saveQueueToStorage();
  }

  /// Retry failed uploads
  void retryFailed() async {
    for (final upload
        in _queue.where((item) => item.status == UploadStatus.failed)) {
      upload.status = UploadStatus.pending;
      upload.retryCount = 0;
      upload.errorMessage = null;
      upload.progress = 0.0;
    }
    _failedCount.value = 0;
    _notifyQueueUpdated();
    await _saveQueueToStorage();
    _processQueue();
  }

  /// Remove upload from queue
  void removeUpload(String uploadId) async {
    _queue.removeWhere((item) => item.id == uploadId);
    _notifyQueueUpdated();
    await _saveQueueToStorage();
  }

  /// Save queue to local storage
  Future<void> _saveQueueToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = _queue.map((item) => item.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(queueJson));
  }

  /// Load queue from local storage
  Future<void> _loadQueueFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString(_queueKey);
    _queue.clear();
    _completedCount.value = 0;
    _failedCount.value = 0;

    if (queueString != null) {
      final queueJson = jsonDecode(queueString) as List;
      _queue.assignAll(
        queueJson.map((item) => QueuedUpload.fromJson(item)).toList(),
      );

      // Reset uploading status to pending on app restart
      for (final upload
          in _queue.where((item) => item.status == UploadStatus.uploading)) {
        upload.status = UploadStatus.pending;
        upload.progress = 0.0;
      }

      // Update counters
      _completedCount.value =
          _queue.where((item) => item.status == UploadStatus.completed).length;
      _failedCount.value =
          _queue.where((item) => item.status == UploadStatus.failed).length;

      await _saveQueueToStorage();
      _notifyQueueUpdated();
    }
  }

  /// Listen to connectivity changes
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork =
          results.any((result) => result != ConnectivityResult.none);
      if (hasNetwork && !_isProcessing.value && !_isPaused.value) {
        _processQueue();
      }
    });
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    return {
      'total': _queue.length,
      'pending': pendingCount,
      'completed': _completedCount.value,
      'failed': _failedCount.value,
      'processing': _isProcessing.value,
      'paused': _isPaused.value,
    };
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}
