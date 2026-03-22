part of 'admin_task_assignments_view.dart';

extension _AdminTaskAssignmentsViewActionsPart
    on _AdminTaskAssignmentsViewState {
  Future<void> _loadUser() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nickname = normalizeNicknameInput(_nicknameController.text);
    if (nickname.isEmpty) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.tasks.username_required'.tr,
      );
      return;
    }
    _updateViewState(() {
      _searching = true;
    });
    try {
      final data = await _userRepository.findUserByNickname(nickname);
      if (!mounted) return;
      if (data == null) {
        AppSnackbar(
          'admin.tasks.not_found'.tr,
          'admin.tasks.user_not_found'.tr,
        );
        _updateViewState(() {
          _selectedUser = null;
          _selectedTaskIds = <String>[];
        });
        return;
      }
      final assignment =
          await _assignmentRepository.fetchAssignment(data['id'].toString());
      if (!mounted) return;
      _updateViewState(() {
        _selectedUser = data;
        _selectedTaskIds = normalizeAdminTaskIds(
          assignment?['taskIds'] is List
              ? assignment!['taskIds'] as List
              : const [],
        );
      });
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.tasks.load_failed'.tr} $e',
      );
    } finally {
      _updateViewState(() {
        _searching = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    final user = _selectedUser;
    if (user == null) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.tasks.load_user_first'.tr,
      );
      return;
    }
    _updateViewState(() {
      _saving = true;
    });
    try {
      final nickname = (user['nickname'] ?? '').toString();
      if (_selectedTaskIds.isEmpty) {
        await _assignmentRepository.clearAssignment(
          (user['id'] ?? '').toString(),
        );
        if (!mounted) return;
        _updateViewState(() {
          _selectedTaskIds = <String>[];
        });
        AppSnackbar(
          'admin.tasks.title'.tr,
          'admin.tasks.assignment_removed'.trParams({'nickname': nickname}),
        );
        return;
      }
      await _assignmentRepository.saveAssignment(
        userId: (user['id'] ?? '').toString(),
        nickname: nickname,
        displayName: (user['displayName'] ?? '').toString(),
        avatarUrl: (user['avatarUrl'] ?? '').toString(),
        rozet: (user['rozet'] ?? '').toString(),
        taskIds: _selectedTaskIds,
        updatedBy: _currentUid,
      );
      AppSnackbar(
        'admin.tasks.title'.tr,
        'admin.tasks.saved'.trParams({'nickname': nickname}),
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.tasks.save_failed'.tr} $e',
      );
    } finally {
      _updateViewState(() {
        _saving = false;
      });
    }
  }

  Future<void> _clearTasks() async {
    final user = _selectedUser;
    if (user == null) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.tasks.load_user_first'.tr,
      );
      return;
    }
    _updateViewState(() {
      _clearing = true;
    });
    try {
      await _assignmentRepository.clearAssignment(
        (user['id'] ?? '').toString(),
      );
      if (!mounted) return;
      _updateViewState(() {
        _selectedTaskIds = <String>[];
      });
      AppSnackbar(
        'admin.tasks.title'.tr,
        'admin.tasks.cleared'.trParams({
          'nickname': (user['nickname'] ?? '').toString(),
        }),
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.tasks.clear_failed'.tr} $e',
      );
    } finally {
      _updateViewState(() {
        _clearing = false;
      });
    }
  }

  void _selectAssignment(Map<String, dynamic> data) {
    final nickname = (data['nickname'] ?? '').toString().trim();
    _updateViewState(() {
      _nicknameController.text = nickname.isEmpty ? '' : '@$nickname';
      _selectedUser = <String, dynamic>{
        'id': (data['userId'] ?? '').toString(),
        'nickname': nickname,
        'displayName': (data['displayName'] ?? '').toString(),
        'avatarUrl': (data['avatarUrl'] ?? '').toString(),
        'rozet': (data['rozet'] ?? '').toString(),
      };
      _selectedTaskIds = normalizeAdminTaskIds(
        data['taskIds'] is List ? data['taskIds'] as List : const [],
      );
    });
  }
}
