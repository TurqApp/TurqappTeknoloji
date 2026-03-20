part of 'post_creator_controller.dart';

extension PostCreatorControllerPublishPart on PostCreatorController {
  Future<void> showReshareSets() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                  SizedBox(width: 12),
                  Text(
                    'post_creator.reshare_privacy_title'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 0;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'post_creator.reshare_everyone_desc'.tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 0
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 1;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'post_creator.reshare_followers_desc'.tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 1
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  paylasimSelection.value = 2;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'post_creator.reshare_closed_desc'.tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: paylasimSelection.value == 2
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }

  Future<void> showPublishModePicker() async {
    // İstenen davranış: Saat ikonuna basınca doğrudan tarih/zaman seçim bottom sheet'i açılsın.
    // Kullanıcı tarih seçerse programlı paylaşım aktif olur; iptal ederse mevcut durum korunur (şimdi paylaş).
    Get.bottomSheet(
      FutureDatePickerBottomSheet(
        initialDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 1,
        ),
        maximumDate: maxIzBirakDate,
        withTime: true,
        onSelected: (v) {
          publishMode.value = 1;
          izBirakDateTime.value =
              v.isAfter(maxIzBirakDate) ? maxIzBirakDate : v;
        },
        title: 'post_creator.schedule_title'.tr,
      ),
      isScrollControlled: true,
    );
  }

  Future<List<PostsModel>> uploadAllPosts(
      UploadProgressController progressController) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishPost)) {
      return <PostsModel>[];
    }
    final allPosts = <PreparedPostModel>[];
    final uploadedPosts = <PostsModel>[];
    final uuid = const Uuid().v4();

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
      final reusedVideoThumbnail = contentController.reusedVideoThumbnail.value;
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

    for (int index = 0; index < allPosts.length; index++) {
      final post = allPosts[index];
      final docID = '${uuid}_$index';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final uid = await _ensureStorageUploadAuthReady() ??
          FirebaseAuth.instance.currentUser!.uid;

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
        for (int j = 0; j < post.images.length; j++) {
          final url = await WebpUploadService.uploadBytesAsWebp(
            storage: FirebaseStorage.instance,
            bytes: post.images[j],
            storagePathWithoutExt: 'Posts/$docID/image_$j',
            maxWidth: 600,
            maxHeight: 600,
          );
          imageUrls.add(CdnUrlBuilder.toCdnUrl(url));
        }
      }

      if (post.gif.isNotEmpty) {
        imageUrls.add(post.gif);
      }

      if (post.video != null) {
        final nsfwVideo = await OptimizedNSFWService.checkVideo(post.video!);
        if (nsfwVideo.errorMessage != null) {
          throw Exception('post_creator.video_nsfw_check_failed'.tr);
        }
        if (nsfwVideo.isNSFW) {
          throw Exception('Uygunsuz video tespit edildi');
        }
        final videoSize = await post.video!.length();
        if (videoSize > PostCreatorController._maxVideoBytesForStorageRule) {
          throw Exception('VIDEO_NOT_REDUCED_UNDER_LIMIT');
        }
        final videoRef = FirebaseStorage.instance.ref().child(
              'Posts/$docID/video.mp4',
            );
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
          // Determine dynamic min width based on device width (fallback to constant)
          int minW = UploadConstants.thumbnailMaxWidth;
          try {
            final ctx = Get.context;
            if (ctx != null) {
              final w = MediaQuery.of(ctx).size.width;
              if (w.isFinite) {
                minW = w
                    .clamp(200, UploadConstants.thumbnailMaxWidth.toDouble())
                    .toInt();
              }
            }
          } catch (_) {}
          // Convert thumbnail to WebP for better size
          Uint8List thumbWebp;
          try {
            thumbWebp = await FlutterImageCompress.compressWithList(
              thumbnailData,
              quality: 80,
              format: CompressFormat.webp,
              minWidth: minW,
            );
          } catch (_) {
            thumbWebp = thumbnailData; // fallback
          }
          final thumbUrl = await WebpUploadService.uploadBytesAsWebp(
            storage: FirebaseStorage.instance,
            bytes: thumbWebp,
            storagePathWithoutExt: 'Posts/$docID/thumbnail',
          );
          thumbnailUrl = CdnUrlBuilder.toCdnUrl(thumbUrl);
        }
      } else if (isReusedVideoPost) {
        videoUrl = post.reusedVideoUrl.trim();
        if (post.reusedVideoThumbnail.trim().isNotEmpty) {
          thumbnailUrl = post.reusedVideoThumbnail.trim();
        }
      }

      double aspectRatio = 1;
      if (isReusedImagePost && imageUrls.length == 1) {
        aspectRatio =
            post.reusedImageAspectRatio > 0 ? post.reusedImageAspectRatio : 0.8;
      } else if (post.images.length == 1 &&
          post.video == null &&
          !isReusedVideoPost) {
        final codec = await ui.instantiateImageCodec(post.images.first);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        aspectRatio = image.width / image.height;
      } else if (post.images.isEmpty && post.video != null) {
        final controller = VideoPlayerController.file(post.video!);
        await controller.initialize();
        aspectRatio = controller.value.aspectRatio;
        await controller.dispose();
      } else if (isReusedVideoPost) {
        aspectRatio = post.reusedVideoAspectRatio > 0
            ? post.reusedVideoAspectRatio
            : 9 / 16;
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

      final RegExp tagExp = RegExp(r"#([\p{L}\p{N}_]+)", unicode: true);
      final matches = tagExp.allMatches(post.text);
      final localTags = matches
          .map((e) => e.group(1)!.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (index == 0) {
        allHashtags.addAll(localTags);
      }

      // Compute publish time: if scheduled, use selected time; else now
      // Update progress for database save
      progressController.updateProgress(
        current: index + 1,
        fileName: 'post_creator.publish_item'.trParams({
          'index': '${index + 1}',
        }),
        statusText: 'post_creator.saving_to_database'.tr,
      );

      final scheduledDate = _normalizedIzBirakDateTime();
      final scheduledMs = scheduledDate?.millisecondsSinceEpoch ?? 0;
      final publishTime = scheduledMs != 0 ? scheduledMs : nowMs;
      final locationCity =
          post.location.trim().isNotEmpty ? _resolvePostLocationCity() : '';

      final pollPayload = post.poll.isNotEmpty
          ? _normalizePollForSave(post.poll, publishTime)
          : null;

      await FirebaseFirestore.instance.collection("Posts").doc(docID).set({
        "arsiv": false,
        if (!isImagePost) "aspectRatio": aspectRatio,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": index == 0 ? false : true,
        "floodCount": postList.length,
        "gizlendi": false,
        "img": imageUrls,
        "imgMap": imgMap,
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
        "mainFlood": index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
        "metin": post.text,
        "reshareMap": {
          "visibility": paylasimSelection.value,
        },
        "scheduledAt": scheduledMs,
        "sikayetEdildi": false,
        "stabilized": false,
        "tags": index == 0 ? allHashtags.toList() : [],
        "thumbnail": thumbnailUrl,
        "timeStamp": nowMs + index,
        "userID": uid,
        "video": videoUrl,
        "hlsStatus": isReusedVideoPost ? "ready" : "none",
        "hlsMasterUrl": isReusedVideoPost ? videoUrl : "",
        "hlsUpdatedAt": isReusedVideoPost ? nowMs : 0,
        "yorumMap": {
          "visibility": commentVisibility.value,
        },
        if (pollPayload != null) "poll": pollPayload,
        // Schema: Original attribution fields must always exist
        "originalUserID": _isSharedAsPost ? _sharedOriginalUserID : "",
        "originalPostID": _isSharedAsPost ? _sharedOriginalPostID : "",
        "sourcePostID": _isSharedAsPost ? _sharedSourcePostID : "",
        "sharedAsPost": _isSharedAsPost,
        "quotedPost": _isSharedAsPost ? _isQuotedPost : false,
        "quotedOriginalText":
            (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
        "quotedSourceUserID":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
        "quotedSourceDisplayName":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceDisplayName : "",
        "quotedSourceUsername":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUsername : "",
        "quotedSourceAvatarUrl":
            (_isSharedAsPost && _isQuotedPost) ? _quotedSourceAvatarUrl : "",
      });
      unawaited(
        TypesensePostService.instance.syncPostById(docID).catchError((_) {}),
      );

      if (_isSharedAsPost &&
          _sharedOriginalUserID.isNotEmpty &&
          _sharedOriginalPostID.isNotEmpty &&
          index == 0) {
        try {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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
          isAd: false,
          ad: false,
          izBirakYayinTarihi: publishTime,
          stats: PostStats(),
          konum: post.location,
          locationCity: locationCity,
          mainFlood: index == 0 ? "" : "${docID.replaceAll("_0", "")}_0",
          metin: post.text,
          paylasGizliligi: paylasimSelection.value,
          reshareMap: {
            "visibility": paylasimSelection.value,
          },
          scheduledAt: scheduledMs,
          sikayetEdildi: false,
          stabilized: false,
          tags: index == 0 ? allHashtags.toList() : [],
          thumbnail: thumbnailUrl,
          timeStamp: nowMs + index,
          userID: FirebaseAuth.instance.currentUser!.uid,
          video: videoUrl,
          hlsStatus: isReusedVideoPost ? "ready" : "none",
          hlsMasterUrl: isReusedVideoPost ? videoUrl : "",
          hlsUpdatedAt: isReusedVideoPost ? nowMs : 0,
          yorum: comment.value,
          yorumMap: {
            "visibility": commentVisibility.value,
          },
          poll: pollPayload ?? const {},
          originalUserID: _isSharedAsPost ? _sharedOriginalUserID : "",
          originalPostID: _isSharedAsPost ? _sharedOriginalPostID : "",
          quotedPost: _isSharedAsPost ? _isQuotedPost : false,
          quotedOriginalText:
              (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : "",
          quotedSourceUserID:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : "",
          quotedSourceDisplayName: (_isSharedAsPost && _isQuotedPost)
              ? _quotedSourceDisplayName
              : "",
          quotedSourceUsername:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUsername : "",
          quotedSourceAvatarUrl:
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceAvatarUrl : "",
        ),
      );

      // Sayaç güncelle: kök post (index==0) ve hemen yayınlanıyorsa
      if (index == 0 && publishTime == nowMs) {
        try {
          final me = FirebaseAuth.instance.currentUser?.uid;
          if (me != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(me)
                .update({'counterOfPosts': FieldValue.increment(1)});
          }
        } catch (_) {}
      }
    }
    return uploadedPosts;
  }

  /// Upload directly with error handling
}
