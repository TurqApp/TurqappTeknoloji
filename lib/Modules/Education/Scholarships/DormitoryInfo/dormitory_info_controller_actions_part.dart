part of 'dormitory_info_controller.dart';

extension DormitoryInfoControllerActionsPart on DormitoryInfoController {
  void showIdariSec() {
    Get.bottomSheet(
      AppBottomSheet(
        list: subList.map(localizedAdminType).toList(),
        title: 'dormitory.select_admin_type'.tr,
        startSelection: localizedAdminType(sub.value),
        onBackData: (v) {
          sub.value = normalizedAdminType(v);
          yurt.value = '';
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showIlSec() {
    Get.bottomSheet(
      ListBottomSheet(
        list: sehirler,
        title: 'common.select_city'.tr,
        startSelection: isCityUnselected ? null : sehir.value,
        onBackData: (v) {
          sehir.value = v;
          ilce.value = '';
          yurt.value = '';
          yurtSelectionController.clear();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void showYurtSec() {
    final filteredYurtList = yurtList
        .where(
          (item) =>
              item.sub == normalizedAdminType(sub.value).toUpperCase() &&
              item.ilAdi == sehir.value.toUpperCase(),
        )
        .map((item) => item.adi)
        .toList();

    if (filteredYurtList.isEmpty) {
      AppSnackbar('common.warning'.tr, 'dormitory.not_found_for_filters'.tr);
      return;
    }

    Get.bottomSheet(
      ListBottomSheet(
        list: filteredYurtList,
        title: 'dormitory.select_dormitory'.tr,
        startSelection: yurt.value.isEmpty ? null : yurt.value,
        onBackData: (v) {
          yurt.value = v;
          listedeYok.value = false;
          yurtInput.clear();
          yurtInputText.value = '';
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  void toggleListedeYok() {
    listedeYok.value = !listedeYok.value;
    if (listedeYok.value) {
      yurt.value = '';
      yurtSelectionController.clear();
    } else {
      yurtInput.clear();
      yurtInputText.value = '';
    }
  }

  void selectYurt(DormitoryModel item) {
    yurt.value = item.adi;
    sehir.value = DormitoryInfoController._selectCity;
    sub.value = DormitoryInfoController._selectAdminType;
    listedeYok.value = false;
    yurtInput.clear();
    yurtInputText.value = '';
    yurtSelectionController.text = item.adi;
  }

  Future<void> saveData() async {
    if ((listedeYok.value && yurtInputText.value.isNotEmpty) ||
        (!listedeYok.value && yurt.value.isNotEmpty)) {
      try {
        final savedYurt = listedeYok.value ? yurtInputText.value : yurt.value;
        await _userRepository.updateUserFields(
          CurrentUserService.instance.effectiveUserId,
          scopedUserUpdate(
            scope: 'family',
            values: {'yurt': savedYurt},
          ),
        );
        yurt.value = savedYurt;
        Get.back();
        AppSnackbar('common.success'.tr, 'dormitory.saved'.tr);
      } catch (_) {
        AppSnackbar('common.error'.tr, 'dormitory.save_failed'.tr);
      }
    } else {
      AppSnackbar('common.error'.tr, 'dormitory.select_or_enter'.tr);
    }
  }
}
