part of 'interest_controller.dart';

extension InterestsControllerRuntimePart on InterestsController {
  String canonicalize(String value) => _canonicalize(value);

  String _norm(String value) {
    return normalizeSearchText(value).replaceAll(RegExp(r'\s+'), ' ');
  }

  String _canonicalize(String value) {
    final normalized = _norm(value);
    for (final item in interestList) {
      if (_norm(item) == normalized) {
        return item;
      }
    }
    return value.trim();
  }

  bool isSelected(String item) {
    final canonical = _canonicalize(item);
    return selecteds.any((e) => _canonicalize(e) == canonical);
  }

  List<String> filterItems(List<String> allItems) {
    final query = normalizeSearchText(searchText.value);
    if (query.isEmpty) {
      return allItems;
    }
    return allItems
        .where((item) => normalizeSearchText(item).contains(query))
        .toList(growable: false);
  }

  void select(String selection) {
    final canonical = canonicalize(selection);
    final normalizedCanonical = normalizeSearchText(canonical);
    final idx = selecteds.indexWhere(
      (e) => normalizeSearchText(e) == normalizedCanonical,
    );
    if (idx >= 0) {
      selecteds.removeAt(idx);
    } else {
      if (selecteds.length >= interestsMaxSelection) {
        if (!_selectionLimitShown) {
          _selectionLimitShown = true;
          AppSnackbar(
            'interests.limit_title'.tr,
            'interests.limit_body'.trParams({
              'max': '$interestsMaxSelection',
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
    if (selecteds.length < interestsMinSelection) {
      AppSnackbar(
        'interests.min_title'.tr,
        'interests.min_body'.trParams({
          'min': '$interestsMinSelection',
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

  void _handleInterestsOnInit() {
    final currentSelections =
        _userService.currentUser?.ilgialanlari ?? const [];
    selecteds.value = currentSelections
        .map((e) => _canonicalize(e.toString()))
        .toList(growable: false);
    isReady.value = true;
  }
}
