part of 'market_create_controller.dart';

extension MarketCreateControllerSubmissionPart on MarketCreateController {
  Future<void> pickImages() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final remaining = MarketCreateController.maxImages - totalImageCount;
    if (remaining <= 0) {
      AppSnackbar(
        'pasaj.market.limit_title'.tr,
        'pasaj.market.image_limit'
            .trParams({'max': '${MarketCreateController.maxImages}'}),
      );
      return;
    }
    final files = await AppImagePickerService.pickImages(
      ctx,
      maxAssets: remaining,
    );
    if (files.isEmpty) return;
    selectedImages.addAll(files.take(remaining));
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= totalImageCount) return;
    if (index < existingImageUrls.length) {
      existingImageUrls.removeAt(index);
      return;
    }
    selectedImages.removeAt(index - existingImageUrls.length);
  }

  Future<void> saveDraftPreview() async {
    final issue = _validateBase(requiredPrice: false);
    if (issue != null) {
      AppSnackbar('common.info'.tr, issue);
      return;
    }
    await _submit(publish: false);
  }

  Future<void> publishPreview() async {
    final issue = _validateBase(requiredPrice: true);
    if (issue != null) {
      AppSnackbar('common.info'.tr, issue);
      return;
    }
    if (totalImageCount == 0) {
      AppSnackbar(
        'common.info'.tr,
        'pasaj.market.create.need_image'.tr,
      );
      return;
    }
    await _submit(publish: true);
  }

  Map<String, dynamic> buildDraftPayload({
    required bool publish,
    required String itemId,
    required String userId,
    required List<String> imageUrls,
  }) {
    final leaf = selectedLeaf.value;
    final now = int.tryParse(itemId) ?? DateTime.now().millisecondsSinceEpoch;
    final current = CurrentUserService.instance.currentUser;
    final fullName = [
      current?.firstName ?? '',
      current?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final nickname = (current?.nickname ?? '').trim();
    final displayName = fullName.isEmpty ? nickname : fullName;
    final avatarUrl = (current?.avatarUrl ?? '').trim();
    final showPhone = contactPreference.value == 'phone';
    final phoneNumber = showPhone ? _resolveSellerPhone(current) : '';
    final attributes = <String, dynamic>{};
    if (leaf != null) {
      for (final field in leaf.fields) {
        final fieldKey = (field['key'] ?? '').toString();
        final label = (field['label'] ?? fieldKey).toString();
        final value = fieldValue(fieldKey);
        if (value.isNotEmpty) {
          attributes[label] = value;
        }
      }
    }
    return {
      'id': itemId,
      'userId': userId,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(
            priceController.text.trim().replaceAll(',', '.'),
          ) ??
          0,
      'currency': 'TRY',
      'categoryKey': leaf?.key ?? '',
      'categoryPath': leaf?.pathLabels ?? const <String>[],
      'attributes': attributes,
      'city': selectedCity.value,
      'district': selectedDistrict.value,
      'locationText': [selectedDistrict.value, selectedCity.value]
          .where((value) => value.trim().isNotEmpty)
          .join(', '),
      'contactPreference': contactPreference.value,
      'showPhone': showPhone,
      'status': _nextStatus(publish),
      'seller': {
        'userId': userId,
        'displayName': displayName.isEmpty
            ? 'pasaj.market.default_seller'.tr
            : displayName,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'rozet': current?.rozet ?? '',
        'phoneNumber': phoneNumber,
        'isApproved': current?.hesapOnayi == true,
        'name': displayName.isEmpty
            ? 'pasaj.market.default_seller'.tr
            : displayName,
        'username': nickname,
        'photoUrl': avatarUrl,
        'verified': current?.hesapOnayi == true,
      },
      'sellerDisplayName':
          displayName.isEmpty ? 'pasaj.market.default_seller'.tr : displayName,
      'sellerNickname': nickname,
      'sellerAvatarUrl': avatarUrl,
      'sellerRozet': current?.rozet ?? '',
      'sellerName':
          displayName.isEmpty ? 'pasaj.market.default_seller'.tr : displayName,
      'sellerUsername': nickname,
      'sellerPhotoUrl': avatarUrl,
      'sellerPhoneNumber': phoneNumber,
      'coverImageUrl': imageUrls.isEmpty ? '' : imageUrls.first,
      'imageUrls': imageUrls,
      'imageCount': imageUrls.length,
      'isNegotiable': true,
      'updatedAt': now,
      'createdAt': initialItem?.createdAt ?? now,
      if (!isEditing) 'offerCount': 0,
      if (!isEditing) 'favoriteCount': 0,
      if (!isEditing) 'reportCount': 0,
      if (!isEditing) 'viewCount': 0,
      if (!isEditing) 'publishedAt': publish ? now : 0,
      if (isEditing && publish && initialItem?.status == 'draft')
        'publishedAt': now,
    };
  }

  String _resolveSellerPhone(dynamic current) {
    final values = <String>[
      (current?.phoneNumber ?? '').toString().trim(),
      CurrentUserService.instance.phoneNumber.trim(),
    ];
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String? _validateBase({required bool requiredPrice}) {
    if (selectedLeaf.value == null) {
      return 'pasaj.market.create.pick_category'.tr;
    }
    if (titleController.text.trim().isEmpty) {
      return 'pasaj.market.create.title_required'.tr;
    }
    if (requiredPrice) {
      final price = double.tryParse(
        priceController.text.trim().replaceAll(',', '.'),
      );
      if (price == null || price <= 0) {
        return 'pasaj.market.create.invalid_price'.tr;
      }
    }
    if (selectedCity.value.isEmpty || selectedDistrict.value.isEmpty) {
      return 'pasaj.market.create.city_district_required_short'.tr;
    }
    final leaf = selectedLeaf.value;
    if (leaf != null) {
      for (final field in leaf.fields) {
        if (field['required'] != true) continue;
        final key = (field['key'] ?? '').toString();
        if (fieldValue(key).isEmpty) {
          return 'pasaj.market.create.field_required'
              .trParams({'field': (field['label'] ?? key).toString()});
        }
      }
    }
    return null;
  }

  Future<void> _submit({required bool publish}) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishMarket)) {
      return;
    }
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.market.user_session_not_found'.tr,
      );
      return;
    }

    final itemId =
        initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    isSubmitting.value = true;
    try {
      final imageUrls = await _uploadImages(uid: uid, itemId: itemId);
      final payload = buildDraftPayload(
        publish: publish,
        itemId: itemId,
        userId: uid,
        imageUrls: imageUrls,
      );
      await _repository.saveItem(
        docId: itemId,
        payload: payload,
        userId: uid,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(payload);
      } else {
        Get.back(result: payload);
      }
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.market.create.save_failed'.trParams({'error': '$e'}),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<List<String>> _uploadImages({
    required String uid,
    required String itemId,
  }) async {
    if (selectedImages.isEmpty) {
      return existingImageUrls.toList(growable: false);
    }
    final urls = existingImageUrls.toList(growable: true);
    for (var i = 0; i < selectedImages.length; i++) {
      final file = selectedImages[i];
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        throw Exception('pasaj.market.image_security_failed'.tr);
      }
      if (nsfw.isNSFW) {
        throw Exception('pasaj.market.image_nsfw_detected'.tr);
      }
      final imageIndex = existingImageUrls.length + i;
      final path = imageIndex == 0
          ? 'marketStore/$uid/$itemId/cover'
          : 'marketStore/$uid/$itemId/image_$imageIndex';
      final url = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: path,
      );
      urls.add(url);
    }
    return urls;
  }

  String _nextStatus(bool publish) {
    if (!publish) return 'draft';
    if (!isEditing) return 'active';
    if (initialItem?.status == 'draft') return 'active';
    return initialItem?.status ?? 'active';
  }
}
