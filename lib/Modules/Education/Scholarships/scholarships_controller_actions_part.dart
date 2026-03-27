part of 'scholarships_controller.dart';

extension _ScholarshipsControllerActionsPart on ScholarshipsController {
  Future<void> _toggleFollowImpl(String followedId) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    if (currentUserId.isEmpty) return;
    final wasFollowing = followedUsers[followedId] ?? false;
    followLoading[followedId] = true;
    try {
      final outcome = await FollowService.toggleFollowFromLocalState(
        followedId,
        assumedFollowing: wasFollowing,
      );
      if (outcome.limitReached) {
        AppSnackbar(
          'common.warning'.tr,
          'follow.daily_limit_reached'.tr,
        );
        return;
      }
      followedUsers[followedId] = outcome.nowFollowing;
    } finally {
      followLoading[followedId] = false;
    }
  }

  void _updatePageIndexImpl(int scholarshipIndex, int pageIndex) {
    pageIndices[scholarshipIndex]?.value = pageIndex;
  }

  Future<void> _toggleLikeImpl(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }
    final wasLiked = likedScholarships[docId] ?? false;

    try {
      likedScholarships[docId] = !wasLiked;
      if (wasLiked) {
        _likedByCurrentUser.remove(docId);
      } else {
        _likedByCurrentUser.add(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['likesCount'] ?? 0) as int;
        final next = (current + (wasLiked ? -1 : 1)).clamp(0, 1 << 30);
        allScholarships[index]['likesCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['likesCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['likesCount'] =
            (current + (wasLiked ? -1 : 1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }

      await _scholarshipRepository.toggleLike(docId, userId: userId);
    } catch (_) {
      likedScholarships[docId] = wasLiked;
      if (wasLiked) {
        _likedByCurrentUser.add(docId);
      } else {
        _likedByCurrentUser.remove(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['likesCount'] ?? 0) as int;
        final next = (current + (wasLiked ? 1 : -1)).clamp(0, 1 << 30);
        allScholarships[index]['likesCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['likesCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['likesCount'] =
            (current + (wasLiked ? 1 : -1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }
      AppSnackbar('common.error'.tr, 'scholarship.like_failed'.tr);
    }
  }

  Future<void> _toggleBookmarkImpl(String docId, String type) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }
    final wasBookmarked = bookmarkedScholarships[docId] ?? false;

    try {
      bookmarkedScholarships[docId] = !wasBookmarked;
      if (wasBookmarked) {
        _bookmarkedByCurrentUser.remove(docId);
      } else {
        _bookmarkedByCurrentUser.add(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['bookmarksCount'] ?? 0) as int;
        final next = (current + (wasBookmarked ? -1 : 1)).clamp(0, 1 << 30);
        allScholarships[index]['bookmarksCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['bookmarksCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['bookmarksCount'] =
            (current + (wasBookmarked ? -1 : 1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }

      await _scholarshipRepository.toggleBookmark(docId, userId: userId);
    } catch (_) {
      bookmarkedScholarships[docId] = wasBookmarked;
      if (wasBookmarked) {
        _bookmarkedByCurrentUser.add(docId);
      } else {
        _bookmarkedByCurrentUser.remove(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['bookmarksCount'] ?? 0) as int;
        final next = (current + (wasBookmarked ? 1 : -1)).clamp(0, 1 << 30);
        allScholarships[index]['bookmarksCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['bookmarksCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['bookmarksCount'] =
            (current + (wasBookmarked ? 1 : -1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }
      AppSnackbar('common.error'.tr, 'scholarship.bookmark_failed'.tr);
    }
  }

  Future<void> _shareScholarshipImpl(
    Map<String, dynamic> scholarshipData,
    BuildContext context,
  ) async {
    final burs = scholarshipData['model'];
    final currentUid = CurrentUserService.instance.effectiveUserId;
    final ownerUid =
        (burs?.userID ?? scholarshipData['userID'] ?? '').toString();
    final canShare = AdminAccessService.isKnownAdminSync() ||
        (ownerUid.isNotEmpty && ownerUid == currentUid);
    if (!canShare) {
      AppSnackbar('common.error'.tr, 'scholarship.share_owner_only'.tr);
      return;
    }
    await _shareScholarshipPublicLink(scholarshipData, burs);
  }

  Future<void> _shareScholarshipExternallyImpl(
    Map<String, dynamic> scholarshipData,
  ) async {
    final burs = scholarshipData['model'];
    await _shareScholarshipPublicLink(scholarshipData, burs);
  }

  Future<void> _shareScholarshipPublicLink(
    Map<String, dynamic> scholarshipData,
    dynamic burs,
  ) async {
    final docId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    if (docId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.share_missing_id'.tr);
      return;
    }
    final shareId = 'scholarship:$docId';
    final shortTail = docId.length >= 8 ? docId.substring(0, 8) : docId;
    final fallbackId = 'scholarship-$shortTail';
    final fallbackUrl = 'https://turqapp.com/e/$fallbackId';
    final title = _pickScholarshipTitle(scholarshipData, burs);
    final normalizedTitle = normalizeSearchText(title);
    final shortDesc = burs.shortDescription.trim();
    final providerDesc = burs.bursVeren.trim();
    final desc = shortDesc.isNotEmpty &&
            normalizeSearchText(shortDesc) != normalizedTitle
        ? shortDesc
        : (providerDesc.isNotEmpty &&
                normalizeSearchText(providerDesc) != normalizedTitle
            ? providerDesc
            : 'scholarship.share_fallback_desc'.tr);
    final existingShortUrl = _readTextField(scholarshipData, 'shortUrl');
    final shareImageUrl = _pickScholarshipImageFromData(scholarshipData, burs);
    try {
      await ShareActionGuard.run(() async {
        final shortUrl = await ShortLinkService().getEducationPublicUrl(
          shareId: shareId,
          title: title,
          desc: desc,
          imageUrl: shareImageUrl,
        );
        final resolvedUrl = shortUrl.trim().isNotEmpty &&
                shortUrl.trim() != 'https://turqapp.com'
            ? shortUrl
            : (existingShortUrl.isNotEmpty ? existingShortUrl : fallbackUrl);

        await ShareLinkService.shareUrl(
          url: resolvedUrl,
          title: title,
          subject: title,
        );
      });
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.share_failed'.tr);
    }
  }

  void _prefetchShortLinksForList(List<Map<String, dynamic>> list) {
    final items = list.take(_scholarshipShortLinkPrefetchLimit).toList();
    for (final item in items) {
      final docId = (item['docId'] ?? '').toString();
      if (docId.isEmpty) continue;
      final shareId = 'scholarship:$docId';
      if (_shortLinkCache.containsKey(shareId) ||
          _shortLinkInFlight.contains(shareId)) {
        continue;
      }
      _shortLinkInFlight.add(shareId);
      final model = item['model'] as IndividualScholarshipsModel?;
      final title = model != null
          ? _pickScholarshipTitle(item, model)
          : 'scholarship.share_detail_title'.tr;
      final imageUrl =
          model != null ? _pickScholarshipImageFromData(item, model) : null;
      unawaited(() async {
        try {
          final shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: title,
            desc: model != null
                ? _pickScholarshipShareDesc(model)
                : 'scholarship.share_fallback_desc'.tr,
            imageUrl: imageUrl,
          );
          if (shortUrl.trim().isNotEmpty &&
              shortUrl.trim() != 'https://turqapp.com') {
            _shortLinkCache[shareId] = shortUrl;
          }
        } catch (_) {
        } finally {
          _shortLinkInFlight.remove(shareId);
        }
      }());
    }
  }

  String? _pickScholarshipShareImage(IndividualScholarshipsModel model) {
    final img = model.img.trim();
    if (img.isNotEmpty) return img;
    final img2 = model.img2.trim();
    if (img2.isNotEmpty) return img2;
    final logo = model.logo.trim();
    if (logo.isNotEmpty) return logo;
    return _scholarshipDefaultOgImage;
  }

  String _readTextField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _pickScholarshipTitle(
    Map<String, dynamic> data,
    IndividualScholarshipsModel model,
  ) {
    final fromBaslik = _readTextField(data, 'baslik');
    if (fromBaslik.isNotEmpty) return fromBaslik;
    return model.baslik.trim();
  }

  String? _pickScholarshipImageFromData(
    Map<String, dynamic> data,
    IndividualScholarshipsModel model,
  ) {
    final img = _readTextField(data, 'img');
    if (img.isNotEmpty) return img;
    final img2 = _readTextField(data, 'img2');
    if (img2.isNotEmpty) return img2;
    final logo = _readTextField(data, 'logo');
    if (logo.isNotEmpty) return logo;
    return _pickScholarshipShareImage(model);
  }

  String _pickScholarshipShareDesc(IndividualScholarshipsModel model) {
    final normalizedTitle = normalizeSearchText(model.baslik);
    final shortDesc = model.shortDescription.trim();
    if (shortDesc.isNotEmpty &&
        normalizeSearchText(shortDesc) != normalizedTitle) {
      return shortDesc;
    }
    final provider = model.bursVeren.trim();
    if (provider.isNotEmpty &&
        normalizeSearchText(provider) != normalizedTitle) {
      return provider;
    }
    return 'scholarship.share_fallback_desc'.tr;
  }

  void _toggleExpandedImpl(int index) {
    if (index >= 0 && index < isExpandedList.length) {
      isExpandedList[index].value = !isExpandedList[index].value;
    }
  }

  void _settingsImpl(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1 / 1.2,
            ),
            itemCount: informations.length,
            itemBuilder: (context, index) {
              final item = informations[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  switch (index) {
                    case 0:
                      Get.to(() => PersonelInfoView());
                      break;
                    case 1:
                      Get.to(() => EducationInfoView());
                      break;
                    case 2:
                      Get.to(() => FamilyInfoView());
                      break;
                    case 3:
                      Get.to(() => DormitoryInfoView());
                      break;
                  }
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
