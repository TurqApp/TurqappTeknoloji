part of 'become_verified_account_controller.dart';

extension _BecomeVerifiedAccountControllerRuntimeX
    on BecomeVerifiedAccountController {
  void handleOnInit() {
    _verifiedAccountRepository
        .fetchApplicationState(
      CurrentUserService.instance.effectiveUserId,
    )
        .then((state) {
      existingApplicationStatus.value = state?.status ?? '';
      if (state?.isPending == true) {
        bodySelection.value = 3;
      } else {
        selectItem(verifiedAccountData.first, 0);
        _bindFormListeners();
        _updateCanSubmit();
      }
    });
  }

  void handleOnClose() {
    instagram.dispose();
    twitter.dispose();
    linkedin.dispose();
    tiktok.dispose();
    youtube.dispose();
    website.dispose();
    nickname.dispose();
    aciklama.dispose();
    eDevletBarcodeNo.dispose();
  }

  Future<bool> submitApplication() async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    final uid = CurrentUserService.instance.effectiveUserId;
    try {
      if (uid.isEmpty) {
        AppSnackbar('common.error'.tr, 'become_verified.session_missing'.tr);
        return false;
      }

      final currentUser = CurrentUserService.instance.currentUser;
      final normalizedRequestedNickname = normalizeNicknameInput(nickname.text);
      final currentNickname = (currentUser?.nickname ?? '').trim();
      await _verifiedAccountRepository.submitApplication({
        "userID": uid,
        "selected": selected.value?.title,
        "status": "pending",
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "aciklama": aciklama.text,
        "website": website.text,
        "instagram": instagram.text,
        "twitter": twitter.text,
        "youtube": youtube.text,
        "linkedin": linkedin.text,
        "tiktok": tiktok.text,
        "talepNickname": nickname.text,
        "talepNicknameNormalized": normalizedRequestedNickname,
        "eDevletBarCodeNo": eDevletBarcodeNo.text,
        "currentNickname": currentNickname,
        "turqappUserLink": _buildTurqAppUserLink(
          currentNickname: currentNickname,
          uid: uid,
        ),
        "talepNicknameLink": normalizedRequestedNickname.isEmpty
            ? ''
            : buildTurqAppProfileUrl(normalizedRequestedNickname),
        "instagramUrl": _buildSocialUrl(
          instagram.text,
          prefix: 'https://instagram.com/',
        ),
        "twitterUrl": _buildSocialUrl(
          twitter.text,
          prefix: 'https://x.com/',
        ),
        "youtubeUrl": _buildSocialUrl(
          youtube.text,
          prefix: 'https://youtube.com/@',
        ),
        "linkedinUrl": _buildSocialUrl(
          linkedin.text,
          prefix: 'https://linkedin.com/in/',
        ),
        "tiktokUrl": _buildSocialUrl(
          tiktok.text,
          prefix: 'https://tiktok.com/@',
        ),
        "websiteUrl": normalizeWebsiteUrl(website.text),
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        AppSnackbar('common.info'.tr, 'become_verified.already_received'.tr);
        bodySelection.value = 3;
        existingApplicationStatus.value = 'pending';
        await _verifiedAccountRepository.fetchApplicationState(
          uid,
          forceRefresh: true,
        );
        return false;
      }
      AppSnackbar('common.error'.tr, 'become_verified.submit_failed'.tr);
      return false;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'become_verified.submit_failed'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String _buildSocialUrl(
    String raw, {
    required String prefix,
  }) {
    final normalized = normalizeNicknameInput(raw);
    if (normalized.isEmpty) return '';
    return '$prefix$normalized';
  }

  String _buildTurqAppUserLink({
    required String currentNickname,
    required String uid,
  }) {
    final normalized = normalizeNicknameInput(currentNickname);
    if (normalized.isNotEmpty) {
      return buildTurqAppProfileUrl(normalized);
    }
    return buildTurqAppProfileUrl(uid);
  }
}
