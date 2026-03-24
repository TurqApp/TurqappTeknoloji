import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class InterestsController extends GetxController {
  static InterestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      InterestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static InterestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<InterestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<InterestsController>(tag: tag);
  }

  final RxList<String> selecteds = <String>[].obs;
  final RxString searchText = "".obs;
  final RxBool isReady = false.obs;
  final CurrentUserService _userService = CurrentUserService.instance;
  static const int minSelection = 3;
  static const int maxSelection = 15;
  bool _selectionLimitShown = false;

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
}
