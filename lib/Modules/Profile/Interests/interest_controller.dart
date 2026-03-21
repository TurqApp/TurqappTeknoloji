import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class InterestsController extends GetxController {
  final RxList<String> selecteds = <String>[].obs;
  final RxString searchText = "".obs;
  final RxBool isReady = false.obs;
  final CurrentUserService _userService = CurrentUserService.instance;
  static const int minSelection = 3;
  static const int maxSelection = 15;
  bool _selectionLimitShown = false;

  String _norm(String value) {
    return normalizeSearchText(value).replaceAll(RegExp(r'\s+'), ' ');
  }

  String _canonicalize(String value) {
    final n = _norm(value);
    for (final item in interestList) {
      if (_norm(item) == n) {
        return item;
      }
    }
    return value.trim();
  }

  String canonicalize(String value) => _canonicalize(value);

  bool isSelected(String item) {
    final canonical = _canonicalize(item);
    return selecteds.any((e) => _canonicalize(e) == canonical);
  }

  @override
  void onInit() {
    super.onInit();
    final currentSelections =
        _userService.currentUser?.ilgialanlari ?? const [];
    selecteds.value = currentSelections
        .map((e) => _canonicalize(e.toString()))
        .toList(growable: false);
    isReady.value = true;
  }

  void select(String selection) {
    final canonical = _canonicalize(selection);
    final idx = selecteds.indexWhere((e) => _norm(e) == _norm(canonical));
    if (idx >= 0) {
      selecteds.removeAt(idx);
    } else {
      if (selecteds.length >= maxSelection) {
        if (!_selectionLimitShown) {
          _selectionLimitShown = true;
          AppSnackbar(
            'interests.limit_title'.tr,
            'interests.limit_body'.trParams({
              'max': '$maxSelection',
            }),
          );
        }
        return;
      }
      selecteds.add(canonical);
    }
    selecteds.refresh();
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

  Future<void> setData() async {
    if (selecteds.length < minSelection) {
      AppSnackbar(
        'interests.min_title'.tr,
        'interests.min_body'.trParams({
          'min': '$minSelection',
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
