part of 'edit_post_controller.dart';

extension EditPostControllerActionsPart on EditPostController {
  Future<void> goToLocationMap() async {
    Get.to(
      () => LocationFinderView(
        submitButtonTitle: 'Bu adresi kullan',
        backAdres: (value) {
          adres.value = value;
        },
        backLatLong: (_) {},
      ),
    );
  }

  Future<void> showCommentOptions() async {
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
                    'common.comments'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = true;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'edit_post.comments_everyone'.tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      _buildCommentOptionCircle(selected: yorum.value),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = false;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'post.comments_disabled_none'.tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      _buildCommentOptionCircle(selected: !yorum.value),
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

  Widget _buildCommentOptionCircle({required bool selected}) {
    return Container(
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
            color: selected ? Colors.black : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Future<void> setData() async {
    try {
      final textValidation = UploadValidationService.validateTextLength(
        text.text,
        maxLength: PostCaptionLimits.forCurrentUser(),
      );
      if (!textValidation.isValid) {
        UploadValidationService.showValidationError(
          textValidation.errorMessage ?? 'upload_validation.error_title'.tr,
        );
        return;
      }
      if (!await TextModerationService.ensureAllowed([text.text])) {
        return;
      }

      bekle.value = true;
      final docRef =
          FirebaseFirestore.instance.collection('Posts').doc(model.docID);
      final storage = FirebaseStorage.instance;

      List<String> finalImageUrls = [];
      String? newVideoDownloadUrl;
      String? newThumbnailDownloadUrl;

      if (selectedImages.isNotEmpty) {
        for (int index = 0; index < selectedImages.length; index++) {
          final file = selectedImages[index];
          try {
            final compressed = await MediaCompressionService.compressImage(
              imageFile: file,
              targetQuality: CompressionQuality.high,
            );
            final url = await WebpUploadService.uploadBytesAsWebp(
              storage: storage,
              bytes: compressed.compressedData,
              storagePathWithoutExt: 'Posts/${model.docID}/images/image_$index',
            );
            finalImageUrls.add(CdnUrlBuilder.toCdnUrl(url));
          } catch (_) {
            final downloadUrl = await WebpUploadService.uploadFileAsWebp(
              storage: storage,
              file: file,
              storagePathWithoutExt: 'Posts/${model.docID}/images/image_$index',
            );
            finalImageUrls.add(CdnUrlBuilder.toCdnUrl(downloadUrl));
          }
        }
      } else {
        finalImageUrls = List<String>.from(imageUrls);
      }

      if (_newVideoSelected && videoUrl.value.isNotEmpty) {
        final videoFile = File(videoUrl.value);

        final tempDir = await getTemporaryDirectory();
        final localThumbPath = p.join(
          tempDir.path,
          '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg',
        );
        await VideoEditorBuilder(videoPath: videoFile.path).generateThumbnail(
          positionMs: 0,
          quality: 80,
          outputPath: localThumbPath,
        );

        final thumbDownloadUrl = await WebpUploadService.uploadFileAsWebp(
          storage: storage,
          file: File(localThumbPath),
          storagePathWithoutExt:
              'Posts/${model.docID}/thumbnails/${DateTime.now().millisecondsSinceEpoch}_thumb',
        );
        newThumbnailDownloadUrl = CdnUrlBuilder.toCdnUrl(thumbDownloadUrl);

        final videoKey =
            'Posts/${model.docID}/videos/${p.basename(videoFile.path)}';
        final videoTask = await storage.ref(videoKey).putFile(
              videoFile,
              SettableMetadata(
                contentType: 'video/mp4',
                cacheControl: 'public, max-age=31536000, immutable',
              ),
            );
        newVideoDownloadUrl = CdnUrlBuilder.toCdnUrl(
          await videoTask.ref.getDownloadURL(),
        );
      }

      double aspectRatio;
      final contentIsVideoAfter =
          _newVideoSelected || (model.video.isNotEmpty && !_videoRemoved);
      if (contentIsVideoAfter) {
        final controller = rxVideoController.value;
        if (controller != null && controller.value.isInitialized) {
          final size = controller.value.size;
          aspectRatio = (size.height / size.width > 4 / 3) ? 1.0 : 4 / 3;
        } else {
          aspectRatio = 4 / 3;
        }
      } else {
        if (finalImageUrls.length <= 1) {
          aspectRatio = 4 / 3;
        } else {
          aspectRatio = 1.0;
          aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
        }
      }

      final data = <String, dynamic>{
        'editTime': DateTime.now().millisecondsSinceEpoch,
        'metin': text.text,
        'konum': adres.value,
        'yorum': yorum.value,
        'aspectRatio': aspectRatio,
      };

      if (contentIsVideoAfter) {
        if (_newVideoSelected) {
          data['video'] = newVideoDownloadUrl ?? '';
          data['thumbnail'] = newThumbnailDownloadUrl ?? '';
        }
        data['img'] = [];
      } else {
        data['img'] = finalImageUrls;
        if (_videoRemoved || model.video.isNotEmpty) {
          data['video'] = '';
          data['thumbnail'] = '';
        }
      }

      await docRef.update(data);

      try {
        final agendaCtrl = maybeFindAgendaController();
        if (agendaCtrl != null) {
          final index =
              agendaCtrl.agendaList.indexWhere((e) => e.docID == model.docID);
          if (index != -1) {
            final old = agendaCtrl.agendaList[index];
            final updated = old.copyWith(
              editTime: DateTime.now().millisecondsSinceEpoch,
              metin: text.text,
              konum: adres.value,
              yorum: yorum.value,
              aspectRatio: aspectRatio,
              img: contentIsVideoAfter ? <String>[] : finalImageUrls,
              video: contentIsVideoAfter
                  ? (_newVideoSelected
                      ? (newVideoDownloadUrl ?? old.video)
                      : old.video)
                  : '',
              thumbnail: contentIsVideoAfter
                  ? (_newVideoSelected
                      ? (newThumbnailDownloadUrl ?? old.thumbnail)
                      : old.thumbnail)
                  : '',
            );
            agendaCtrl.agendaList[index] = updated;
            agendaCtrl.agendaList.refresh();
          }

          final editTimestamp = DateTime.now().millisecondsSinceEpoch;
          final candidateTags = <String>{
            model.docID,
            'profile_post_${model.docID}',
            'profile_reshare_${model.docID}',
            'social_post_${model.docID}',
            'social_reshare_${model.docID}',
            'liked_post_${model.docID}',
            'archives_${model.docID}',
            'tag_post_${model.docID}',
            'top_tag_${model.docID}',
            'flood_${model.docID}',
            'explore_series_${model.docID}',
          };
          for (final tag in candidateTags) {
            final contentCtrl = AgendaContentController.maybeFind(tag: tag);
            if (contentCtrl == null) continue;
            contentCtrl.editTime.value = editTimestamp;
          }
        }
      } catch (_) {}

      final profileController = ProfileController.maybeFind();
      if (profileController != null) {
        profileController.fetchPosts(isInitial: true);
        if (contentIsVideoAfter) {
          profileController.fetchVideos(isInitial: true);
        } else {
          profileController.fetchPhotos(isInitial: true);
        }
      }
    } catch (_) {
    } finally {
      bekle.value = false;
      Get.back(result: model.docID);
    }
  }
}
