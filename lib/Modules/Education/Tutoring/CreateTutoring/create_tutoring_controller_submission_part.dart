part of 'create_tutoring_controller.dart';

extension CreateTutoringControllerSubmissionPart on CreateTutoringController {
  Future<List<String>> uploadImages() async {
    final imageUrls = <String>[];
    final storage = firebase_storage.FirebaseStorage.instance;
    final userId = CurrentUserService.instance.effectiveUserId;

    final newLocalImages =
        images.where((imagePath) => !imagePath.startsWith('http')).toList();
    if (images.isEmpty &&
        selectedBranch.value.isNotEmpty &&
        newLocalImages.isEmpty) {
      final iconFileName = branchIconMap[selectedBranch.value];
      if (iconFileName != null) {
        final byteData = await rootBundle.load(
          'assets/tutorings/$iconFileName',
        );
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/$iconFileName');
        try {
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          final downloadUrl = await WebpUploadService.uploadFileAsWebp(
            storage: storage,
            file: tempFile,
            storagePathWithoutExt:
                'users/$userId/${path.basenameWithoutExtension(iconFileName)}_${DateTime.now().millisecondsSinceEpoch}',
          );
          imageUrls.add(downloadUrl);
        } finally {
          try {
            if (await tempFile.exists()) await tempFile.delete();
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
    } else {
      for (final imagePath in newLocalImages) {
        final localFile = File(imagePath);
        final nsfw = await OptimizedNSFWService.checkImage(localFile);
        if (nsfw.errorMessage != null) {
          AppSnackbar(
            'common.error'.tr,
            'tutoring.create.nsfw_check_failed'.tr,
          );
          continue;
        }
        if (nsfw.isNSFW) {
          AppSnackbar(
            'common.error'.tr,
            'tutoring.create.nsfw_detected'.tr,
          );
          continue;
        }
        final downloadUrl = await WebpUploadService.uploadFileAsWebp(
          storage: storage,
          file: localFile,
          storagePathWithoutExt:
              'users/$userId/${path.basenameWithoutExtension(imagePath)}_${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<void> saveTutoring() async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishTutoring)) {
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (_hasMissingRequiredFields) {
        AppSnackbar('common.error'.tr, 'tutoring.create.fill_required'.tr);
        return;
      }

      final imageUrls = await uploadImages();
      final profile = _profileFields();
      final tutoring = TutoringModel(
        docID: '',
        aciklama: descriptionController.text,
        baslik: titleController.text,
        brans: branchController.text,
        cinsiyet: selectedGender.value,
        dersYeri: [selectedLessonPlace.value],
        end: 0,
        favorites: [],
        fiyat: num.tryParse(priceController.text) ?? 0,
        imgs: imageUrls.isNotEmpty ? imageUrls : null,
        ilce: districtController.text,
        onayVerildi: false,
        sehir: cityController.text,
        telefon: isPhoneOpen.value,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
        userID: CurrentUserService.instance.effectiveUserId,
        whatsapp: false,
        availability: availability.isNotEmpty
            ? Map<String, List<String>>.from(availability)
            : null,
        lat: _lat,
        long: _long,
        avatarUrl: profile['avatarUrl'] ?? '',
        displayName: profile['displayName'] ?? '',
        nickname: profile['nickname'] ?? '',
        rozet: profile['rozet'] ?? '',
      );

      final docRef = FirebaseFirestore.instance.collection('educators').doc();
      await docRef.set(tutoring.toJson());
      Get.back();
      AppSnackbar('common.success'.tr, 'tutoring.create.published'.tr);
      clearForm();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tutoring.create.publish_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTutoring(String docId) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (_hasMissingRequiredFields) {
        AppSnackbar('common.error'.tr, 'tutoring.create.fill_required'.tr);
        return;
      }

      final initialData = Get.arguments as TutoringModel?;
      final updateData = <String, dynamic>{};
      final profile = _profileFields();

      if (titleController.text != initialData?.baslik) {
        updateData['baslik'] = titleController.text;
      }
      if (descriptionController.text != initialData?.aciklama) {
        updateData['aciklama'] = descriptionController.text;
      }
      if (branchController.text != initialData?.brans) {
        updateData['brans'] = branchController.text;
      }
      if (num.tryParse(priceController.text) != initialData?.fiyat) {
        updateData['fiyat'] = num.tryParse(priceController.text) ?? 0;
      }
      if (selectedLessonPlace.value !=
          (initialData?.dersYeri.isNotEmpty ?? false
              ? initialData?.dersYeri[0]
              : '')) {
        updateData['dersYeri'] = [selectedLessonPlace.value];
      }
      if (cityController.text != initialData?.sehir) {
        updateData['sehir'] = cityController.text;
      }
      if (districtController.text != initialData?.ilce) {
        updateData['ilce'] = districtController.text;
      }
      if (selectedGender.value != initialData?.cinsiyet) {
        updateData['cinsiyet'] = selectedGender.value;
      }
      if (isPhoneOpen.value != initialData?.telefon) {
        updateData['telefon'] = isPhoneOpen.value;
      }
      if ((profile['avatarUrl'] ?? '') != initialData?.avatarUrl) {
        updateData['avatarUrl'] = profile['avatarUrl'];
      }
      if ((profile['displayName'] ?? '') != initialData?.displayName) {
        updateData['displayName'] = profile['displayName'];
      }
      if ((profile['nickname'] ?? '') != initialData?.nickname) {
        updateData['nickname'] = profile['nickname'];
      }
      if ((profile['rozet'] ?? '') != initialData?.rozet) {
        updateData['rozet'] = profile['rozet'];
      }

      if (availability.isNotEmpty) {
        updateData['availability'] =
            Map<String, List<String>>.from(availability);
      }

      if (_lat != null && _long != null) {
        updateData['lat'] = _lat;
        updateData['long'] = _long;
      }

      final newLocalImages =
          images.where((imagePath) => !imagePath.startsWith('http')).toList();
      if (newLocalImages.isNotEmpty) {
        final imageUrls = await uploadImages();
        updateData['imgs'] = imageUrls.isNotEmpty ? imageUrls : null;
      }

      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('educators')
            .doc(docId)
            .update(updateData);
        final patchedModel = _buildPatchedModel(
          initialData: initialData,
          docId: docId,
          updateData: updateData,
        );
        if (patchedModel != null) {
          _applyLocalTutoringPatch(patchedModel);
        }
        Get.back();
        AppSnackbar('common.success'.tr, 'tutoring.create.updated'.tr);
        clearForm();
      } else {
        Get.back();
        AppSnackbar('common.info'.tr, 'tutoring.create.no_changes'.tr);
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tutoring.create.update_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  bool get _hasMissingRequiredFields =>
      titleController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      branchController.text.isEmpty ||
      priceController.text.isEmpty ||
      selectedLessonPlace.value.isEmpty ||
      cityController.text.isEmpty ||
      selectedGender.value.isEmpty;

  Map<String, String> _profileFields() {
    final current = CurrentUserService.instance.currentUser;
    final nickname =
        (current?.nickname ?? CurrentUserService.instance.nickname).trim();
    final fullName =
        (current?.fullName ?? CurrentUserService.instance.fullName).trim();
    final displayName = fullName.isNotEmpty ? fullName : nickname;
    return {
      'nickname': nickname,
      'displayName': displayName,
      'avatarUrl': CurrentUserService.instance.avatarUrl.trim(),
      'rozet': (current?.rozet ?? '').trim(),
    };
  }

  TutoringModel? _buildPatchedModel({
    required TutoringModel? initialData,
    required String docId,
    required Map<String, dynamic> updateData,
  }) {
    final base = initialData;
    if (base == null) return null;
    return base.copyWith(
      docID: docId,
      baslik: (updateData['baslik'] ?? base.baslik).toString(),
      aciklama: (updateData['aciklama'] ?? base.aciklama).toString(),
      brans: (updateData['brans'] ?? base.brans).toString(),
      fiyat: (updateData['fiyat'] as num?) ?? base.fiyat,
      dersYeri: (updateData['dersYeri'] as List<dynamic>?)
              ?.map((entry) => entry.toString())
              .toList() ??
          base.dersYeri,
      sehir: (updateData['sehir'] ?? base.sehir).toString(),
      ilce: (updateData['ilce'] ?? base.ilce).toString(),
      cinsiyet: (updateData['cinsiyet'] ?? base.cinsiyet).toString(),
      telefon: (updateData['telefon'] as bool?) ?? base.telefon,
      avatarUrl: (updateData['avatarUrl'] ?? base.avatarUrl).toString(),
      displayName: (updateData['displayName'] ?? base.displayName).toString(),
      nickname: (updateData['nickname'] ?? base.nickname).toString(),
      rozet: (updateData['rozet'] ?? base.rozet).toString(),
      availability:
          (updateData['availability'] as Map<String, List<String>>?) ??
              base.availability,
      lat: (updateData['lat'] as double?) ?? base.lat,
      long: (updateData['long'] as double?) ?? base.long,
      imgs: (updateData['imgs'] as List<dynamic>?)
              ?.map((entry) => entry.toString())
              .toList() ??
          base.imgs,
    );
  }

  void _applyLocalTutoringPatch(TutoringModel patchedModel) {
    final controller = TutoringController.maybeFind();
    if (controller != null) {
      final homeIndex = controller.tutoringList.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (homeIndex != -1) {
        controller.tutoringList[homeIndex] = patchedModel;
        controller.tutoringList.refresh();
      }
      final searchIndex = controller.searchResults.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (searchIndex != -1) {
        controller.searchResults[searchIndex] = patchedModel;
        controller.searchResults.refresh();
      }
    }

    final myTutoringsController = MyTutoringsController.maybeFind();
    if (myTutoringsController != null) {
      final ownerIndex = myTutoringsController.myTutorings.indexWhere(
        (item) => item.docID == patchedModel.docID,
      );
      if (ownerIndex != -1) {
        myTutoringsController.myTutorings[ownerIndex] = patchedModel;
        myTutoringsController.myTutorings.refresh();
        myTutoringsController.updateTutoringsStatus();
      }
    }

    final tutoringDetailController = TutoringDetailController.maybeFind();
    if (tutoringDetailController != null &&
        tutoringDetailController.tutoring.value.docID == patchedModel.docID) {
      tutoringDetailController.tutoring.value = patchedModel;
    }
  }
}
