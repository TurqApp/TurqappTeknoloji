part of 'create_scholarship_controller.dart';

extension CreateScholarshipControllerSubmissionPart
    on CreateScholarshipController {
  Future<RenderRepaintBoundary?> _waitForTemplateBoundary() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = templateKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        return boundary;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    final boundary = templateKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary != null && !boundary.debugNeedsPaint) {
      return boundary;
    }
    return null;
  }

  Future<Uint8List?> _compressFileToWebp(File file, {int quality = 85}) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _compressBytesToWebp(
    Uint8List bytes, {
    int quality = 85,
  }) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadImage(String localPath, {bool isLogo = false}) async {
    if (localPath.isEmpty) {
      return null;
    }
    if (localPath.startsWith('http')) {
      return localPath;
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        AppSnackbar('common.error'.tr, 'scholarship.file_missing'.tr);
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        return null;
      }

      final webpBytes = await _compressFileToWebp(file, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.image_convert_failed'.tr);
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage
          .ref()
          .child('scholarships/${isLogo ? 'logos' : 'images'}/$timestamp.webp');
      await ref.putData(
        webpBytes,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.image_upload_failed'.tr);
      return null;
    }
  }

  Future<String?> _captureAndUploadTemplate() async {
    try {
      if (selectedTemplateIndex.value == -1) {
        return null;
      }

      final boundary = await _waitForTemplateBoundary();
      if (boundary == null) {
        return null;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPath);

      if (await file.exists()) {
        await file.delete();
      }
      await file.writeAsBytes(bytes);

      if (!await file.exists()) {
        return null;
      }
      final nsfw = await OptimizedNSFWService.checkImage(file);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
        return null;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        return null;
      }

      final webpBytes = await _compressBytesToWebp(bytes, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) {
        AppSnackbar(
            'common.error'.tr, 'scholarship.template_convert_failed'.tr);
        return null;
      }

      final ref = _storage.ref().child(
            'scholarships/templates/${DateTime.now().millisecondsSinceEpoch}.webp',
          );
      await ref.putData(
        webpBytes,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      final downloadUrl = await ref.getDownloadURL();
      templateUrl.value = downloadUrl;
      template.value = 'template${selectedTemplateIndex.value + 1}';
      return downloadUrl;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.template_capture_failed'.tr);
      return null;
    }
  }

  List<String> _buildAltEducationAudience() {
    final altEgitimKitlesi = <String>[];
    if (egitimKitlesi.value == educationAudienceMiddleSchoolValue) {
      altEgitimKitlesi.add(
        educationAudienceMiddleSchoolValue,
      );
    } else if (egitimKitlesi.value == educationAudienceHighSchoolValue) {
      altEgitimKitlesi.add(
        educationAudienceHighSchoolValue,
      );
    } else if (egitimKitlesi.value == educationAudienceUndergraduateValue) {
      altEgitimKitlesi.addAll(lisansTuru);
    } else if (egitimKitlesi.value == educationAudienceAllValue) {
      altEgitimKitlesi.addAll([
        educationAudienceMiddleSchoolValue,
        educationAudienceHighSchoolValue,
      ]);
      altEgitimKitlesi.addAll(lisansTuru);
    }
    return altEgitimKitlesi;
  }

  String _resolvedEducationAudienceValue() {
    return egitimKitlesi.value == educationAudienceAllValue
        ? educationAudienceAllExpandedValue
        : egitimKitlesi.value;
  }

  IndividualScholarshipsModel _buildScholarshipModel({
    required String customImageUrl,
    required String logoUrl,
  }) {
    return IndividualScholarshipsModel(
      aciklama: aciklama.value,
      shortDescription: '',
      altEgitimKitlesi: _buildAltEducationAudience(),
      aylar: aylar,
      basvurular: [],
      baslangicTarihi: baslangicTarihi.value,
      baslik: baslik.value,
      bursVeren: bursVeren.value,
      basvuruKosullari: basvuruKosullari.value,
      basvuruURL: basvuruURL.value,
      basvuruYapilacakYer: basvuruYapilacakYer.value,
      begeniler: [],
      belgeler: belgeler,
      bitisTarihi: bitisTarihi.value,
      egitimKitlesi: _resolvedEducationAudienceValue(),
      geriOdemeli: geriOdemeli.value,
      goruntuleme: [],
      hedefKitle: hedefKitle.value,
      ilceler: ilceler,
      img: templateUrl.value,
      img2: customImageUrl,
      kaydedenler: [],
      kaydedilenler: [],
      liseOrtaOkulIlceler: [],
      liseOrtaOkulSehirler: [],
      logo: logoUrl,
      mukerrerDurumu: mukerrerDurumu.value,
      ogrenciSayisi: ogrenciSayisi.value,
      sehirler: sehirler,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      tutar: tutar.value,
      universiteler: universiteler,
      userID: _currentUid,
      website: website.value,
      lisansTuru: lisansTuru.join(','),
      template: template.value,
      ulke: ulke.value,
    );
  }

  Future<void> _navigateAfterSubmission(String successMessage) async {
    final scholarshipsController = ensureScholarshipsController();
    scholarshipsController.fetchScholarships();

    try {
      await AppRootNavigationService.offAllToAuthenticatedHome();
      maybeFindNavBarController()?.changeIndex(3);
    } catch (_) {}

    try {
      scholarshipsController.resetSearch();
    } catch (_) {}

    Get.to(() => ScholarshipsView());
    AppSnackbar('common.success'.tr, successMessage);
    resetForm();
  }

  Future<void> saveScholarship() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (!formKey.currentState!.validate()) return;
      if (!await TextModerationService.ensureAllowed(<String?>[
        baslik.value,
        bursVeren.value,
        aciklama.value,
        basvuruYapilacakYer.value,
        basvuruKosullari.value,
        hedefKitle.value,
      ])) {
        return;
      }

      try {
        if (selectedTemplateIndex.value != -1) {
          final templateUrlResult = await _captureAndUploadTemplate();
          if (templateUrlResult == null) {
            AppSnackbar(
              'common.error'.tr,
              'scholarship.template_capture_failed'.tr,
            );
            return;
          }
        }

        final customImageUrl = await _uploadImage(customImagePath.value) ?? '';
        final logoUrl = await _uploadImage(
              logoPath.value,
              isLogo: true,
            ) ??
            '';
        final scholarship = _buildScholarshipModel(
          customImageUrl: customImageUrl,
          logoUrl: logoUrl,
        );
        final authorFields = await _authorFieldsForCurrentUser();

        final docRef = await ScholarshipFirestorePath.collection(
          firestore: _firestore,
        ).add(<String, dynamic>{
          ...scholarship.toJson(),
          ...authorFields,
        });

        await ScholarshipFirestorePath.doc(
          docRef.id,
          firestore: _firestore,
        ).set(
          {'likesCount': 0, 'bookmarksCount': 0},
          SetOptions(merge: true),
        );

        await _navigateAfterSubmission('scholarship.published_success'.tr);
      } catch (_) {
        AppSnackbar('common.error'.tr, 'scholarship.publish_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateScholarship() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (!formKey.currentState!.validate()) return;
      if (!await TextModerationService.ensureAllowed(<String?>[
        baslik.value,
        bursVeren.value,
        aciklama.value,
        basvuruYapilacakYer.value,
        basvuruKosullari.value,
        hedefKitle.value,
      ])) {
        return;
      }

      try {
        if (selectedTemplateIndex.value != -1 &&
            templateKey.currentContext != null) {
          final templateUrlResult = await _captureAndUploadTemplate();
          if (templateUrlResult == null) {
            AppSnackbar(
              'common.error'.tr,
              'scholarship.template_capture_failed'.tr,
            );
            return;
          }
        }

        final customImageUrl = await _uploadImage(customImagePath.value) ?? '';
        final logoUrl = await _uploadImage(
              logoPath.value,
              isLogo: true,
            ) ??
            '';
        final scholarship = _buildScholarshipModel(
          customImageUrl: customImageUrl,
          logoUrl: logoUrl,
        );
        final authorFields = await _authorFieldsForCurrentUser();

        await ScholarshipFirestorePath.doc(
          scholarshipId.value,
          firestore: _firestore,
        ).update(<String, dynamic>{
          ...scholarship.toJson(),
          ...authorFields,
        });

        await _navigateAfterSubmission('scholarship.updated_success'.tr);
      } catch (_) {
        AppSnackbar('common.error'.tr, 'scholarship.update_failed'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
