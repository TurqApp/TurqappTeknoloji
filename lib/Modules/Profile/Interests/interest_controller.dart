import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'interest_controller_data_part.dart';
part 'interest_controller_actions_part.dart';

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
