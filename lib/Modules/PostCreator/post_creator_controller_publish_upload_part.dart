part of 'post_creator_controller.dart';

extension PostCreatorControllerPublishUploadPart on PostCreatorController {
  Future<void> _uploadDirectly(
      UploadProgressController progressController) async {
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        bool hasVideo = false;
        for (final postModel in postList) {
          final controller = ensureComposerControllerFor(postModel.index);
          if (controller.selectedVideo.value != null) {
            hasVideo = true;
            break;
          }
        }
        if (hasVideo) {
          await _addToUploadQueue(progressController);
          return;
        }
        if (!_validatePollRequirements()) {
          nav?.uploadingPosts.value = false;
          return;
        }
        final uploadedPosts =
            await uploadAllPostsWithErrorHandling(progressController);

        if (uploadedPosts.isNotEmpty) {
          // Track data usage
          int totalUploadMB = 0;
          for (final postModel in postList) {
            final controller = ensureComposerControllerFor(postModel.index);
            for (final image in controller.selectedImages) {
              final size = await image.length();
              totalUploadMB += (size / (1024 * 1024)).round();
            }

            if (controller.selectedVideo.value != null) {
              final size = await controller.selectedVideo.value!.length();
              totalUploadMB += (size / (1024 * 1024)).round();
            }
          }

          await _networkRuntimeService.trackDataUsage(uploadMB: totalUploadMB);

          final agendaController = maybeFindAgendaController();
          await Future.delayed(const Duration(milliseconds: 150));

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final nowPosts =
              uploadedPosts.where((e) => e.timeStamp <= nowMs).toList();

          if (kDebugMode) {
            debugPrint(
              '[FeedPublish] directUpload uploaded=${uploadedPosts.length} '
              'nowPosts=${nowPosts.length} '
              'ids=${uploadedPosts.map((post) => post.docID).join(',')}',
            );
          }

          if (agendaController != null && nowPosts.isNotEmpty) {
            final ids = nowPosts.map((e) => e.docID).toList();
            agendaController.markHighlighted(ids);
            agendaController.addUploadedPostsAtTop(nowPosts);
          }

          if (agendaController != null &&
              agendaController.scrollController.hasClients) {
            agendaController.scrollController.jumpTo(0);
          }

          await persistUploadedPostsToHomeFeed(nowPosts);
          unawaited(
            _hydrateUploadedPostShortLinks(
              nowPosts,
              agendaController: agendaController,
            ),
          );
          ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();
          progressController.complete('post_creator.upload_success'.tr);
        } else {
          await _errorService.handleError(
            'No posts uploaded',
            category: ErrorCategory.upload,
            severity: ErrorSeverity.medium,
            userMessage: 'post_creator.no_post_uploaded'.tr,
          );
          progressController.setError('post_creator.upload_error'.tr);
        }
      } catch (e, stackTrace) {
        await _errorService.handleError(
          e,
          category: ErrorCategory.upload,
          severity: ErrorSeverity.critical,
          userMessage: 'post_creator.upload_process_failed'.tr,
          stackTrace: stackTrace,
          isRetryable: true,
        );
        progressController.setError('post_creator.critical_error'.tr);
      } finally {
        nav?.uploadingPosts.value = false;
      }
    });
  }

  /// Upload all posts with comprehensive error handling
  Future<List<PostsModel>> uploadAllPostsWithErrorHandling(
      UploadProgressController progressController) async {
    if (!_validateCaptionLengths()) {
      return <PostsModel>[];
    }
    final allPosts = <PreparedPostModel>[];
    final uploadedPosts = <PostsModel>[];
    final uuid = const Uuid().v4();
    final authorSummary = await _resolveAuthorSummary();
    final authorNickname = authorSummary.nickname;
    final authorUsername = authorSummary.username;
    final authorFullName = authorSummary.fullName;
    final authorDisplayName = authorSummary.displayName;
    final authorAvatarUrl = authorSummary.avatarUrl;
    final authorRozet = authorSummary.rozet;

    try {
      // Prepare all posts
      for (var postModel in postList) {
        final contentController = ensureComposerControllerFor(postModel.index);
        final text = contentController.textEdit.text.trim();
        final images =
            contentController.croppedImages.whereType<Uint8List>().toList();
        final reusedImageUrls = contentController.reusedImageUrls.toList();
        final reusedImageAspectRatio =
            contentController.reusedImageAspectRatio.value;
        final video = contentController.selectedVideo.value;
        final reusedVideoUrl = contentController.reusedVideoUrl.value;
        final reusedVideoThumbnail =
            contentController.reusedVideoThumbnail.value;
        final reusedVideoAspectRatio =
            contentController.reusedVideoAspectRatio.value;
        final videoLookPreset = postList.length > 1
            ? 'original'
            : contentController.videoLookPreset.value.trim();
        const location = '';
        final gif = contentController.gif.value;
        final customThumb = contentController.selectedThumbnail.value;
        final poll = contentController.pollData.value ?? const {};
        final hasPoll =
            poll['options'] is List && (poll['options'] as List).isNotEmpty;

        if (text.isEmpty &&
            images.isEmpty &&
            reusedImageUrls.isEmpty &&
            video == null &&
            reusedVideoUrl.trim().isEmpty &&
            gif.trim().isEmpty &&
            !hasPoll) {
          continue;
        }

        allPosts.add(
          PreparedPostModel(
            text: text,
            images: images,
            reusedImageUrls: reusedImageUrls,
            reusedImageAspectRatio: reusedImageAspectRatio,
            video: video,
            reusedVideoUrl: reusedVideoUrl,
            reusedVideoThumbnail: reusedVideoThumbnail,
            reusedVideoAspectRatio: reusedVideoAspectRatio,
            videoLookPreset:
                videoLookPreset.isEmpty ? 'original' : videoLookPreset,
            location: location,
            gif: gif,
            customThumbnail: customThumb,
            poll: poll,
          ),
        );
      }

      final allHashtags = <String>{};

      // Upload each post with error handling
      for (int index = 0; index < allPosts.length; index++) {
        try {
          final post = allPosts[index];
          final docID = '${uuid}_$index';
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final uid =
              await _ensureStorageUploadAuthReady() ?? _requireCurrentUid();
          final locationCity =
              post.location.trim().isNotEmpty ? _resolvePostLocationCity() : '';

          // Storage rules require Posts/{docID}.userID to exist before media upload.
          await _preparePostShellForStorageUpload(
            docID: docID,
            uid: uid,
            nowMs: nowMs,
          );

          // Update progress
          progressController.updateProgress(
            current: index + 1,
            fileName: 'post_creator.publish_item'.trParams({
              'index': '${index + 1}',
            }),
            statusText: 'post_creator.uploading_media'.tr,
          );

          final imageUrls = <String>[];
          var videoUrl = "";
          var thumbnailUrl = "";
          final isReusedVideoPost =
              post.video == null && post.reusedVideoUrl.trim().isNotEmpty;
          final isReusedImagePost = post.video == null &&
              post.images.isEmpty &&
              post.reusedImageUrls.isNotEmpty;

          if (isReusedImagePost) {
            imageUrls.addAll(post.reusedImageUrls.map(CdnUrlBuilder.toCdnUrl));
          } else {
            // Upload images with retry logic
            for (int j = 0; j < post.images.length; j++) {
              try {
                final url = await WebpUploadService.uploadBytesAsWebp(
                  storage: FirebaseStorage.instance,
                  bytes: post.images[j],
                  storagePathWithoutExt: 'Posts/$docID/image_$j',
                  maxWidth: 600,
                  maxHeight: 600,
                );
                imageUrls.add(CdnUrlBuilder.toCdnUrl(url));
              } catch (e) {
                await _errorService.handleError(
                  e,
                  category: ErrorCategory.upload,
                  severity: ErrorSeverity.high,
                  userMessage: 'post_creator.image_upload_failed'
                      .trParams({'index': '${j + 1}'}),
                  metadata: {'postIndex': index, 'imageIndex': j},
                  isRetryable: true,
                );
                rethrow;
              }
            }
          }

          if (post.gif.isNotEmpty) {
            imageUrls.add(post.gif);
          }

          // Upload video with error handling
          if (post.video != null) {
            try {
              final nsfwVideo =
                  await OptimizedNSFWService.checkVideo(post.video!);
              if (nsfwVideo.errorMessage != null) {
                throw Exception('post_creator.video_nsfw_check_failed'.tr);
              }
              if (nsfwVideo.isNSFW) {
                throw Exception('Uygunsuz video tespit edildi');
              }
              final videoSize = await post.video!.length();
              if (videoSize > _maxVideoBytesForStorageRule) {
                throw Exception('VIDEO_NOT_REDUCED_UNDER_LIMIT');
              }
              final videoRef = FirebaseStorage.instance
                  .ref()
                  .child('Posts/$docID/video.mp4');
              final uploadTask = await _putFileWithAuthRetry(
                ref: videoRef,
                file: post.video!,
                metadata: SettableMetadata(
                  contentType: 'video/mp4',
                  cacheControl: 'public, max-age=31536000, immutable',
                  customMetadata: {
                    'uploaderUid': uid,
                  },
                ),
              );
              videoUrl = CdnUrlBuilder.toCdnUrl(
                await uploadTask.ref.getDownloadURL(),
              );

              Uint8List? thumbnailData;
              if (post.customThumbnail != null) {
                thumbnailData = post.customThumbnail;
              } else {
                thumbnailData = await VideoThumbnail.thumbnailData(
                  video: post.video!.path,
                  imageFormat: ImageFormat.JPEG,
                  quality: 75,
                );
              }

              if (thumbnailData != null) {
                Uint8List thumbWebp;
                try {
                  thumbWebp = await FlutterImageCompress.compressWithList(
                    thumbnailData,
                    quality: 80,
                    format: CompressFormat.webp,
                    minWidth: UploadConstants.thumbnailMaxWidth,
                  );
                } catch (_) {
                  thumbWebp = thumbnailData;
                }
                final thumbUrl = await WebpUploadService.uploadBytesAsWebp(
                  storage: FirebaseStorage.instance,
                  bytes: thumbWebp,
                  storagePathWithoutExt: 'Posts/$docID/thumbnail',
                );
                thumbnailUrl = CdnUrlBuilder.toCdnUrl(
                  thumbUrl,
                );
              }
            } catch (e) {
              final tooLarge =
                  e.toString().contains('VIDEO_NOT_REDUCED_UNDER_LIMIT');
              await _errorService.handleError(
                e,
                category: ErrorCategory.upload,
                severity: ErrorSeverity.high,
                userMessage: tooLarge
                    ? 'post_creator.video_reduce_failed'.tr
                    : 'post_creator.video_upload_failed'.tr,
                metadata: {'postIndex': index},
                isRetryable: !tooLarge,
              );
              rethrow; // Re-throw to stop this post's upload
            }
          } else if (isReusedVideoPost) {
            videoUrl = post.reusedVideoUrl.trim();
            if (post.reusedVideoThumbnail.trim().isNotEmpty) {
              thumbnailUrl = post.reusedVideoThumbnail.trim();
            }
          }

          // Calculate timing
          final scheduledDate = _normalizedIzBirakDateTime();
          final publishTime = scheduledDate?.millisecondsSinceEpoch ?? nowMs;

          // Calculate proper aspect ratio
          double aspectRatio = 1.0;
          if (isReusedImagePost && imageUrls.length == 1) {
            aspectRatio = post.reusedImageAspectRatio > 0
                ? post.reusedImageAspectRatio
                : 0.8;
          } else if (post.images.length == 1 &&
              post.video == null &&
              !isReusedVideoPost) {
            try {
              final codec = await ui.instantiateImageCodec(post.images.first);
              final frame = await codec.getNextFrame();
              final image = frame.image;
              aspectRatio = image.width / image.height;
            } catch (e) {
              aspectRatio = 4.0 / 5.0; // Default for images
            }
          } else if (post.images.isEmpty && post.video != null) {
            try {
              final controller = VideoPlayerController.file(post.video!);
              await controller.initialize();
              aspectRatio = controller.value.aspectRatio;
              await controller.dispose();
            } catch (e) {
              aspectRatio = 16.0 / 9.0; // Default for videos
            }
          } else if (isReusedVideoPost) {
            aspectRatio = post.reusedVideoAspectRatio > 0
                ? post.reusedVideoAspectRatio
                : 9.0 / 16.0;
          } else {
            aspectRatio =
                4.0 / 5.0; // Default for multiple images or mixed content
          }

          // Normalize to 4 decimals
          aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
          final isImagePost = imageUrls.isNotEmpty && videoUrl.isEmpty;
          final List<Map<String, dynamic>> imgMap = [];
          for (int i = 0; i < imageUrls.length; i++) {
            double itemAspect = 1.0;
            try {
              if (isReusedImagePost && imageUrls.length == 1) {
                itemAspect = post.reusedImageAspectRatio > 0
                    ? post.reusedImageAspectRatio
                    : itemAspect;
              } else if (i < post.images.length) {
                final codec = await ui.instantiateImageCodec(post.images[i]);
                final frame = await codec.getNextFrame();
                final image = frame.image;
                if (image.height > 0) {
                  itemAspect = image.width / image.height;
                }
              }
            } catch (_) {}
            imgMap.add({
              'url': imageUrls[i],
              'aspectRatio': double.parse(itemAspect.toStringAsFixed(4)),
            });
          }

          // Upload to Firestore with error handling
          try {
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(docID)
                .set({
              // ... (same data structure as before)
              "arsiv": false,
              if (!isImagePost) "aspectRatio": aspectRatio,
              "debugMode": false,
              "deletedPost": false,
              "deletedPostTime": 0,
              "flood": index == 0 ? false : true,
              "floodCount": allPosts.length,
              "gizlendi": false,
              "img": imageUrls,
              "imgMap": imgMap,
              "isUploading": false,
              "isAd": false,
              "ad": false,
              "izBirakYayinTarihi": publishTime,
              "stats": {
                "commentCount": 0,
                "likeCount": 0,
                "reportedCount": 0,
                "retryCount": 0,
                "savedCount": 0,
                "statsCount": 0
              },
              "konum": post.location,
              "locationCity": locationCity,
              "mainFlood":
                  index == 0 ? "" : resolvePostCreatorFloodRootDocId(docID),
              "metin": post.text,
              "reshareMap": {
                "visibility": paylasimSelection.value,
              },
              "scheduledAt": scheduledDate?.millisecondsSinceEpoch ?? 0,
              "sikayetEdildi": false,
              "stabilized": false,
              "tags": index == 0 ? allHashtags.toList() : [],
              "thumbnail": thumbnailUrl,
              "timeStamp": nowMs + index,
              "userID": uid,
              "authorNickname": authorNickname,
              "authorDisplayName": authorDisplayName,
              "authorAvatarUrl": authorAvatarUrl,
              "nickname": authorNickname,
              "username": authorUsername,
              "fullName": authorFullName,
              "displayName": authorDisplayName,
              "avatarUrl": authorAvatarUrl,
              "rozet": authorRozet,
              "video": videoUrl,
              "videoLook": {
                "preset": post.videoLookPreset,
                "version": 1,
                "intensity": 1.0,
              },
              "hlsStatus": isReusedVideoPost ? "ready" : "none",
              "hlsMasterUrl": isReusedVideoPost ? videoUrl : "",
              "hlsUpdatedAt": isReusedVideoPost ? nowMs : 0,
              "yorumMap": {
                "visibility": commentVisibility.value,
              },
              if (post.poll.isNotEmpty) "poll": post.poll,
              "originalUserID": _isSharedAsPost ? _sharedOriginalUserID : "",
              "originalPostID": _isSharedAsPost ? _sharedOriginalPostID : "",
              "sourcePostID": _isSharedAsPost ? _sharedSourcePostID : "",
              "sharedAsPost": _isSharedAsPost,
              "quotedPost": _isSharedAsPost ? _isQuotedPost : false,
              "quotedOriginalText":
                  (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
              "quotedSourceUserID":
                  (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
              "quotedSourceDisplayName": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceDisplayName
                  : "",
              "quotedSourceUsername": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceUsername
                  : "",
              "quotedSourceAvatarUrl": (_isSharedAsPost && _isQuotedPost)
                  ? _quotedSourceAvatarUrl
                  : "",
            });
            unawaited(
              TypesensePostService.instance
                  .syncPostById(docID)
                  .catchError((_) {}),
            );

            if (_isSharedAsPost &&
                _sharedOriginalUserID.isNotEmpty &&
                _sharedOriginalPostID.isNotEmpty &&
                index == 0) {
              try {
                final currentUserId = _requireCurrentUid();
                final shareTimestamp = DateTime.now().millisecondsSinceEpoch;
                final counterTargetPostId = _isQuotedPost
                    ? await resolveQuoteCounterTargetPostId()
                    : _sharedOriginalPostID;
                await FirebaseFirestore.instance
                    .collection("Posts")
                    .doc(counterTargetPostId.isNotEmpty
                        ? counterTargetPostId
                        : _sharedOriginalPostID)
                    .collection("postSharers")
                    .doc(currentUserId)
                    .set({
                  "userID": currentUserId,
                  "timestamp": shareTimestamp,
                  "sharedPostID": docID,
                }, SetOptions(merge: true));
                if (_isQuotedPost) {
                  await FirebaseFirestore.instance
                      .collection("Posts")
                      .doc(counterTargetPostId.isNotEmpty
                          ? counterTargetPostId
                          : _sharedOriginalPostID)
                      .update({
                    'stats.retryCount': FieldValue.increment(1),
                  });
                }
              } catch (_, __) {}
            }

            // Create PostsModel
            uploadedPosts.add(
              PostsModel(
                arsiv: false,
                aspectRatio: aspectRatio,
                debugMode: false,
                deletedPost: false,
                deletedPostTime: 0,
                docID: docID,
                flood: index == 0 ? false : true,
                floodCount: allPosts.length,
                gizlendi: false,
                img: imageUrls,
                isUploading: false,
                isAd: false,
                ad: false,
                izBirakYayinTarihi: publishTime,
                stats: PostStats(),
                konum: post.location,
                locationCity: locationCity,
                mainFlood:
                    index == 0 ? "" : resolvePostCreatorFloodRootDocId(docID),
                metin: post.text,
                originalPostID: _isSharedAsPost ? _sharedOriginalPostID : "",
                originalUserID: _isSharedAsPost ? _sharedOriginalUserID : "",
                paylasGizliligi: paylasimSelection.value,
                reshareMap: {
                  "visibility": paylasimSelection.value,
                },
                scheduledAt: scheduledDate?.millisecondsSinceEpoch ?? 0,
                sikayetEdildi: false,
                stabilized: false,
                tags: index == 0 ? allHashtags.toList() : [],
                thumbnail: thumbnailUrl,
                timeStamp: nowMs + index,
                userID: uid,
                authorNickname: authorNickname,
                authorAvatarUrl: authorAvatarUrl,
                video: videoUrl,
                videoLook: {
                  "preset": post.videoLookPreset,
                  "version": 1,
                  "intensity": 1.0,
                },
                hlsStatus: isReusedVideoPost ? "ready" : "none",
                hlsMasterUrl: isReusedVideoPost ? videoUrl : "",
                hlsUpdatedAt: isReusedVideoPost ? nowMs : 0,
                yorum: comment.value,
                yorumMap: {
                  "visibility": commentVisibility.value,
                },
                quotedPost: _isSharedAsPost ? _isQuotedPost : false,
                quotedOriginalText: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedOriginalText
                    : "",
                quotedSourceUserID: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceUserID
                    : "",
                quotedSourceDisplayName: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceDisplayName
                    : "",
                quotedSourceUsername: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceUsername
                    : "",
                quotedSourceAvatarUrl: (_isSharedAsPost && _isQuotedPost)
                    ? _quotedSourceAvatarUrl
                    : "",
                poll: post.poll,
              ),
            );

            // Update counter for root post
            if (index == 0 && publishTime == nowMs) {
              try {
                await CurrentUserService.instance.applyLocalCounterDelta(
                  postsDelta: 1,
                );
              } catch (e) {
                await _errorService.handleError(
                  e,
                  category: ErrorCategory.storage,
                  severity: ErrorSeverity.low,
                  userMessage: 'post_creator.post_counter_failed'.tr,
                  showToUser: false,
                );
              }
            }
          } catch (e) {
            await _errorService.handleError(
              e,
              category: ErrorCategory.storage,
              severity: ErrorSeverity.high,
              userMessage: 'post_creator.firestore_save_failed'.tr,
              metadata: {'postIndex': index, 'docID': docID},
              isRetryable: true,
            );
            rethrow; // Re-throw to stop this post's upload
          }
        } catch (e) {
          // Log the error for this specific post but continue with others
          await _errorService.handleError(
            e,
            category: ErrorCategory.upload,
            severity: ErrorSeverity.high,
            userMessage: 'post_creator.post_upload_failed'
                .trParams({'index': '${index + 1}'}),
            metadata: {'postIndex': index},
            isRetryable: false,
          );
          // Continue with next post instead of stopping everything
          continue;
        }
      }

      return uploadedPosts;
    } catch (e, stackTrace) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.critical,
        userMessage: 'post_creator.upload_process_failed'.tr,
        stackTrace: stackTrace,
        isRetryable: true,
      );
      return [];
    }
  }
}
