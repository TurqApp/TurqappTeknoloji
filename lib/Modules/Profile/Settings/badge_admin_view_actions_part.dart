part of 'badge_admin_view.dart';

extension _BadgeAdminViewActionsPart on _BadgeAdminViewState {
  Future<void> _saveBadge() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nickname = normalizeNicknameInput(_nicknameController.text);
    if (nickname.isEmpty) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.tasks.username_required'.tr,
      );
      return;
    }

    _updateBadgeAdminState(() {
      _saving = true;
    });

    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        final user = await _userRepository.findUserByNickname(nickname);
        if (user == null) {
          AppSnackbar(
            'support.error_title'.tr,
            'admin.tasks.user_not_found'.tr,
          );
          return;
        }
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'admin.badges.change_approval_title'.tr,
          summary: _selectedBadge.isEmpty
              ? 'admin.badges.remove_badge_summary'
                  .trParams(<String, String>{'nickname': nickname})
              : 'admin.badges.give_badge_summary'.trParams(
                  <String, String>{
                    'nickname': nickname,
                    'badge': _localizedBadgeTitle(_selectedBadge),
                  },
                ),
          targetUserId: (user['id'] ?? '').toString(),
          targetNickname: (user['nickname'] ?? '').toString(),
          payload: <String, dynamic>{
            'userId': (user['id'] ?? '').toString(),
            'rozet': _badgeStorageValue(_selectedBadge),
          },
        );
        AppSnackbar(
          'admin.badges.title'.tr,
          'admin.badges.sent_for_approval'.tr,
        );
        return;
      }

      final callable = AppCloudFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByNickname');
      final response = await callable.call<Map<String, dynamic>>({
        'nickname': nickname,
        'rozet': _badgeStorageValue(_selectedBadge),
      });

      final result = _BadgeChangeResult.fromMap(
        Map<String, dynamic>.from(response.data),
      );
      if (!mounted) return;
      _updateBadgeAdminState(() {
        _lastResult = result;
      });
      AppSnackbar(
        'admin.badges.title'.tr,
        result.badge.isEmpty
            ? 'admin.badges.badge_removed'.trParams(
                <String, String>{'nickname': result.nickname},
              )
            : 'admin.badges.badge_saved'.trParams(<String, String>{
                'nickname': result.nickname,
                'badge': _localizedBadgeTitle(
                  _badgeKeyFromStorageValue(result.badge),
                ),
              }),
      );
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar('support.error_title'.tr, _errorMessage(e));
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.badges.save_failed'.tr}: $e',
      );
    } finally {
      _updateBadgeAdminState(() {
        _saving = false;
      });
    }
  }

  String _errorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'not-found':
        return 'admin.tasks.user_not_found'.tr;
      case 'permission-denied':
        return 'admin.badges.permission_required'.tr;
      case 'invalid-argument':
        return error.message ?? 'admin.badges.invalid_input'.tr;
      case 'failed-precondition':
        return 'admin.badges.multiple_users'.tr;
      default:
        return error.message ?? 'admin.badges.save_failed'.tr;
    }
  }
}
