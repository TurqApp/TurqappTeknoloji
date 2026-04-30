part of 'upload_queue_service.dart';

extension UploadQueueServiceProcessingPart on UploadQueueService {
  bool _uploadQueueProcessingAsBool(
    Object? value, {
    required bool fallback,
  }) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  int _uploadQueueProcessingAsInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) return fallback;
    return int.tryParse(normalized) ??
        num.tryParse(normalized)?.toInt() ??
        fallback;
  }

  Future<void> _performRefreshAuthTokenIfNeeded() async {
    try {
      await CurrentUserService.instance.refreshAuthTokenIfNeeded();
    } catch (_) {
      // Best effort only.
    }
  }

  Future<TaskSnapshot> _performPutFileWithAuthRetry({
    required Reference ref,
    required File file,
    required SettableMetadata metadata,
  }) async {
    try {
      return await ref.putFile(file, metadata);
    } on FirebaseException catch (e) {
      if (!_isUploadQueueAuthRetryableStorageError(e)) rethrow;
      await _performRefreshAuthTokenIfNeeded();
      return await ref.putFile(file, metadata);
    }
  }

  void _performProcessQueue() async {
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

  Future<void> _performProcessUpload(QueuedUpload upload) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork =
          connectivity.any((result) => result != ConnectivityResult.none);
      if (!hasNetwork) {
        upload.status = UploadStatus.failed;
        upload.errorMessage = 'upload_queue.no_internet'.tr;
        await _saveQueueToStorage();
        AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
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
      final String userID = _resolveUploadQueueActiveUserId(postDataMap);
      if (userID.isEmpty) {
        throw Exception('userID boş: upload sırasında oturum bulunamadı');
      }
      final Map<String, dynamic> yorumMap =
          Map<String, dynamic>.from(postDataMap['yorumMap'] ?? {});
      final Map<String, dynamic> reshareMap =
          Map<String, dynamic>.from(postDataMap['reshareMap'] ?? {});
      final Map<String, dynamic> poll =
          Map<String, dynamic>.from(postDataMap['poll'] ?? {});
      final bool sharedAsPost = _uploadQueueProcessingAsBool(
        postDataMap['sharedAsPost'],
        fallback: false,
      );
      final String originalUserID =
          (postDataMap['originalUserID'] ?? '').toString().trim();
      final String originalPostID =
          (postDataMap['originalPostID'] ?? '').toString().trim();
      final String sourcePostID =
          (postDataMap['sourcePostID'] ?? '').toString().trim();
      final bool quotedPost = _uploadQueueProcessingAsBool(
        postDataMap['quotedPost'],
        fallback: false,
      );
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
      final String authorNickname = _uploadQueueFirstNonEmptyValue([
        normalizeHandleInput(postDataMap['nickname']?.toString() ?? ''),
        normalizeHandleInput(postDataMap['authorNickname']?.toString() ?? ''),
        normalizeHandleInput(currentUser.nickname),
      ]);
      final String username = _uploadQueueFirstNonEmptyValue([
        normalizeHandleInput(postDataMap['username']?.toString() ?? ''),
      ]);
      final String fullName = _uploadQueueFirstNonEmptyValue([
        postDataMap['fullName'],
        postDataMap['authorDisplayName'],
        postDataMap['displayName'],
        currentUser.fullName,
        authorNickname,
      ]);
      final String authorDisplayName = _uploadQueueFirstNonEmptyValue([
        postDataMap['authorDisplayName'],
        postDataMap['displayName'],
        fullName,
        authorNickname,
      ]);
      final String authorAvatarUrl =
          (postDataMap['authorAvatarUrl'] ?? currentUser.avatarUrl)
              .toString()
              .trim();
      final String authorRozet = _uploadQueueFirstNonEmptyValue([
        postDataMap['rozet'],
        currentUser.currentUser?.rozet.trim() ?? '',
      ]);
      if (yorumMap.isEmpty) {
        final bool comment = _uploadQueueProcessingAsBool(
          postDataMap['comment'],
          fallback: true,
        );
        yorumMap['visibility'] = comment ? 0 : 3;
      }
      if (reshareMap.isEmpty) {
        final int paylasGizliligi = _uploadQueueProcessingAsInt(
          postDataMap['paylasGizliligi'],
        );
        reshareMap['visibility'] = paylasGizliligi;
      }
      final int scheduledAt = _uploadQueueProcessingAsInt(
        postDataMap['scheduledAt'],
      );
      final int postTimeStamp = _uploadQueueProcessingAsInt(
        postDataMap['timeStamp'],
      );

      bool flood = false;
      String mainFlood = '';
      try {
        final idxStr = upload.id.substring(upload.id.lastIndexOf('_') + 1);
        final idx = _uploadQueueProcessingAsInt(idxStr);
        flood = idx != 0;
        if (flood) {
          mainFlood = '${upload.id}_0';
        }
      } catch (_) {}

      int floodCount = 1;
      try {
        final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
        floodCount = _queue.where((q) => q.id.startsWith('${base}_')).length;
        if (floodCount <= 0) floodCount = 1;
      } catch (_) {}

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final publishTime = scheduledAt != 0
          ? scheduledAt
          : (postTimeStamp != 0 ? postTimeStamp : nowMs);

      for (final imagePath in upload.imagePaths) {
        final file = File(imagePath);
        if (!await file.exists()) continue;
        final nsfwImage = await OptimizedNSFWService.checkImage(file);
        if (nsfwImage.errorMessage != null) {
          upload.status = UploadStatus.failed;
          upload.errorMessage = 'upload_queue.nsfw_image_check_failed'.tr;
          await AppFirestore.instance
              .collection('Posts')
              .doc(upload.id)
              .delete()
              .catchError((_) {});
          await _saveQueueToStorage();
          AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
          return;
        }
        if (nsfwImage.isNSFW) {
          upload.status = UploadStatus.failed;
          upload.errorMessage = 'upload_queue.nsfw_image_detected'.tr;
          await AppFirestore.instance
              .collection('Posts')
              .doc(upload.id)
              .delete()
              .catchError((_) {});
          await _saveQueueToStorage();
          AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
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
            upload.errorMessage = 'upload_queue.video_too_large'.tr;
            await AppFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
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
            upload.errorMessage = 'upload_queue.nsfw_video_check_failed'.tr;
            await AppFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
            return;
          }
          if (nsfwVideo.isNSFW) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'upload_queue.nsfw_video_detected'.tr;
            await AppFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .delete()
                .catchError((_) {});
            await _saveQueueToStorage();
            AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
            return;
          }
        }
      }

      await AppFirestore.instance.collection('Posts').doc(upload.id).set({
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
        "timeStamp": postTimeStamp != 0 ? postTimeStamp : publishTime,
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
        "hlsStatus": "none",
        "hlsMasterUrl": "",
        "hlsUpdatedAt": 0,
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

      final imageUrls = <String>[];
      for (int i = 0; i < upload.imagePaths.length; i++) {
        final imagePath = upload.imagePaths[i];
        final file = File(imagePath);

        if (await file.exists()) {
          final nsfwImage = await OptimizedNSFWService.checkImage(file);
          if (nsfwImage.errorMessage != null) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'upload_queue.nsfw_image_check_failed'.tr;
            await _saveQueueToStorage();
            AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
            return;
          }
          if (nsfwImage.isNSFW) {
            upload.status = UploadStatus.failed;
            upload.errorMessage = 'upload_queue.nsfw_image_detected'.tr;
            await _saveQueueToStorage();
            AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
            return;
          }
          final localBytes = await file.readAsBytes();
          final url = await WebpUploadService.uploadBytesAsWebp(
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

      String videoUrl = '';
      String thumbnailUrl = '';
      int thumbWidth = 0;
      int thumbHeight = 0;
      if (upload.videoPath != null) {
        final videoFile = checkedVideoFile ?? File(upload.videoPath!);
        if (await videoFile.exists()) {
          final ref = AppFirebaseStorage.instance.ref().child(
                'Posts/${upload.id}/video.mp4',
              );
          if (kDebugMode) {
            final postDoc = await AppFirestore.instance
                .collection('Posts')
                .doc(upload.id)
                .get();
            debugPrint('[UploadPreflight][Queue] postExists=${postDoc.exists}');
          }

          final uploadTask = await _performPutFileWithAuthRetry(
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
          videoUrl = CdnUrlBuilder.toCdnUrl(
            await uploadTask.ref.getDownloadURL(),
          );
          if (kDebugMode) {
            final len = await videoFile.length();
            debugPrint('[Queue] Video uploaded successfully '
                'size=${(len / 1e6).toStringAsFixed(2)} MB');
          }

          final tData = await VideoThumbnail.thumbnailData(
            video: videoFile.path,
            imageFormat: ImageFormat.JPEG,
            quality: 75,
          );
          if (tData != null) {
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

            final im = img.decodeImage(tData);
            if (im != null) {
              thumbWidth = im.width;
              thumbHeight = im.height;
            }
          }
        }
      }

      upload.progress = 0.95;
      _notifyQueueUpdated();

      if (gif.isNotEmpty) {
        imageUrls.add(gif);
      }

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

      final tagExp = RegExp(r"#([\p{L}\p{N}_]+)", unicode: true);
      final allTags = tagExp
          .allMatches(text)
          .map((e) => e.group(1)!.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final isPendingVideoProcessing = videoUrl.isNotEmpty;

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
        "timeStamp": postTimeStamp != 0 ? postTimeStamp : publishTime,
        "userID": userID,
        "video": isPendingVideoProcessing ? "" : videoUrl,
        "isUploading": isPendingVideoProcessing,
        "hlsStatus": isPendingVideoProcessing ? "processing" : "none",
        "hlsMasterUrl": "",
        "hlsUpdatedAt": 0,
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
      };

      await AppFirestore.instance
          .collection('Posts')
          .doc(upload.id)
          .set(data, SetOptions(merge: true));
      PostRepository.ensure().mergeCachedPostData(upload.id, data);
      if (!flood && scheduledAt == 0) {
        try {
          if (CurrentUserService.instance.effectiveUserId.trim() == userID) {
            await CurrentUserService.instance.applyLocalCounterDelta(
              postsDelta: 1,
            );
          }
        } catch (_) {}
      }
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
          await AppFirestore.instance
              .collection('Posts')
              .doc(originalPostID)
              .collection('postSharers')
              .doc(userID)
              .set({
            'userID': userID,
            'timestamp': shareTimestamp,
            'sharedPostID': upload.id,
          }, SetOptions(merge: true));
          if (quotedPost) {
            final counterTargetPostId = await _resolveQuoteCounterTargetPostId(
              sourcePostId: sourcePostID,
              originalPostId: originalPostID,
            );
            await AppFirestore.instance
                .collection('Posts')
                .doc(counterTargetPostId.isNotEmpty
                    ? counterTargetPostId
                    : originalPostID)
                .update({
              'stats.retryCount': FieldValue.increment(1),
            });
          }
        } catch (_) {}
      }

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
        await AppFirestore.instance
            .collection('Posts')
            .doc(upload.id)
            .delete()
            .catchError((_) {});
        AppSnackbar('upload_queue.failed_title'.tr, upload.errorMessage!);
      } else {
        upload.status = UploadStatus.pending;
        upload.errorMessage =
            'Retry ${upload.retryCount}/$_maxRetries: ${e.toString()}';

        await Future.delayed(Duration(seconds: upload.retryCount * 2));
      }

      await _saveQueueToStorage();
      _notifyQueueUpdated();
    }
  }
}
