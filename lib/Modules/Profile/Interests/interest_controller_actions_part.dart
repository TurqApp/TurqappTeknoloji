part of 'interest_controller.dart';

extension InterestsControllerActionsPart on InterestsController {
  void select(String selection) {
    final canonical = canonicalize(selection);
    final normalizedCanonical = normalizeSearchText(canonical);
    final idx = selecteds.indexWhere(
      (e) => normalizeSearchText(e) == normalizedCanonical,
    );
    if (idx >= 0) {
      selecteds.removeAt(idx);
    } else {
      if (selecteds.length >= InterestsController.maxSelection) {
        if (!_selectionLimitShown) {
          _selectionLimitShown = true;
          AppSnackbar(
            'interests.limit_title'.tr,
            'interests.limit_body'.trParams({
              'max': '${InterestsController.maxSelection}',
            }),
          );
        }
        return;
      }
      selecteds.add(canonical);
    }
    selecteds.refresh();
  }

  Future<void> setData() async {
    if (selecteds.length < InterestsController.minSelection) {
      AppSnackbar(
        'interests.min_title'.tr,
        'interests.min_body'.trParams({
          'min': '${InterestsController.minSelection}',
        }),
      );
      return;
    }

    await _userService.updateFields(
      scopedUserUpdate(
        scope: 'preferences',
        values: {"ilgialanlari": selecteds.toList(growable: false)},
      ),
    );

    Get.back();
  }
}
