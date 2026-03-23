part of 'editor_nickname_controller.dart';

extension EditorNicknameControllerActionsPart on EditorNicknameController {
  Future<void> setData() async {
    final normalized = currentNormalized;

    nicknameController.value = nicknameController.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );

    if (normalized.length < 8) {
      AppSnackbar('common.error'.tr, 'editor_nickname.error_min_length'.tr);
      return;
    }
    try {
      final existing = await _userRepository.findUserByNickname(
        normalized,
        preferCache: true,
      );
      if (existing != null && (existing['id'] ?? '').toString() != uid) {
        throw Exception('taken');
      }

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('changeOwnNickname')
          .call(<String, dynamic>{'nickname': normalized});

      _originalNickname = normalized;
      await _refreshNicknameSurfaces();
      await AccountCenterService.ensure().refreshCurrentAccountMetadata();
      await fetchAndSetUserData();
      Get.back();
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          'EditorNicknameController.setData callable error: ${e.code} ${e.message}');
      if (e.code == 'already-exists' ||
          (e.message ?? '').contains('nickname_already_taken')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_taken'.tr);
      } else if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('grace_limit')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_grace_limit'.tr);
      } else if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('cooldown')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_cooldown'.tr);
      } else if (e.code == 'invalid-argument' &&
          (e.message ?? '').contains('nickname_too_short')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_min_length'.tr);
      } else {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_update_failed'.tr);
      }
    } catch (e) {
      debugPrint('EditorNicknameController.setData error: $e');
      if (e.toString().contains('taken')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_taken'.tr);
      } else if (e.toString().contains('grace_limit')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_grace_limit'.tr);
      } else if (e.toString().contains('cooldown')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_cooldown'.tr);
      } else {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_update_failed'.tr);
      }
    }
  }

  Future<void> _refreshNicknameSurfaces() async {
    await UserProfileCacheService.invalidateIfRegistered(uid);
    PostContentController.invalidateUserProfileCache(uid);
    await CurrentUserService.instance.forceRefresh();
    await StoryRowController.refreshStoriesGlobally();
  }
}
