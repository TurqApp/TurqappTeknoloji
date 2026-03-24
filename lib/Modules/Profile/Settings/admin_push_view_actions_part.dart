part of 'admin_push_view.dart';

extension AdminPushViewActionsPart on _AdminPushViewState {
  Future<void> _showMeslekSelector() async {
    await Get.bottomSheet(
      ListBottomSheet(
        list: allJobs,
        title: 'admin.push.select_job'.tr,
        startSelection: _selectedMeslek,
        onBackData: (value) {
          if (value is String) {
            _updateViewState(() {
              _selectedMeslek = value;
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
    );
  }

  Future<List<String>> _resolveTargetUids({
    required String uid,
    required String meslek,
    required String konum,
    required String gender,
    required int? minAge,
    required int? maxAge,
  }) async {
    return _adminPushRepository.resolveTargetUids(
      filters: AdminPushTargetFilters(
        uid: uid,
        meslek: meslek,
        konum: konum,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
      ),
    );
  }

  Future<void> _sendPush() async {
    if (!_canManagePush) {
      AppSnackbar(
        'admin.push.permission_title'.tr,
        'admin.push.permission_body'.tr,
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final uid = _uidController.text.trim();
    final meslek = _selectedMeslek.trim();
    final konum = _konumController.text.trim();
    final gender = _genderController.text.trim();
    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final type = _selectedType;

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.push.required_title_body'.tr,
      );
      return;
    }
    if (minAge != null && maxAge != null && minAge > maxAge) {
      AppSnackbar(
        'admin.push.invalid_range_title'.tr,
        'admin.push.invalid_range_body'.tr,
      );
      return;
    }

    _updateViewState(() {
      _sending = true;
    });

    try {
      final targetUids = await _resolveTargetUids(
        uid: uid,
        meslek: meslek,
        konum: konum,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
      );
      final senderUid = _currentUid.isEmpty ? 'admin' : _currentUid;

      if (targetUids.isEmpty) {
        AppSnackbar(
          'admin.push.no_results_title'.tr,
          'admin.push.no_results_body'.tr,
        );
        return;
      }

      await _adminPushRepository.sendPush(
        title: title,
        body: body,
        type: type,
        targetUids: targetUids,
      );

      if (!mounted) return;
      _updateViewState(() {
        final now = DateTime.now();
        _lastReport =
            "Saat ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n"
            "${'admin.push.target'.tr}: ${targetUids.length} ${'admin.push.user_count'.tr}\n"
            "${'admin.push.type'.tr}: $type\n"
            "UID: ${uid.isEmpty ? '-' : uid}\n"
            "${'admin.push.job'.tr}: ${meslek.isEmpty ? '-' : meslek}\n"
            "${'admin.push.location'.tr}: ${konum.isEmpty ? '-' : konum}\n"
            "${'admin.push.gender'.tr}: ${gender.isEmpty ? '-' : gender}\n"
            "${'admin.push.age'.tr}: ${minAge?.toString() ?? '-'} - ${maxAge?.toString() ?? '-'}";
      });
      try {
        await _adminPushRepository.addReport(
          senderUid: senderUid,
          title: title,
          body: body,
          type: type,
          targetCount: targetUids.length,
          filters: AdminPushTargetFilters(
            uid: uid,
            meslek: meslek,
            konum: konum,
            gender: gender,
            minAge: minAge,
            maxAge: maxAge,
          ),
        );
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      AppSnackbar(
        'admin.push.started_title'.tr,
        'admin.push.started_body'
            .trParams(<String, String>{'count': '${targetUids.length}'}),
      );
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'support.error_title'.tr,
        "${'admin.push.send_failed'.tr}: $e",
      );
    } finally {
      if (mounted) {
        _updateViewState(() {
          _sending = false;
        });
      }
    }
  }
}
