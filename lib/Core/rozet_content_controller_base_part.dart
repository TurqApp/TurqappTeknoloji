part of 'rozet_content.dart';

abstract class _RozetControllerBase extends GetxController {
  _RozetControllerBase(this.userID);

  final String userID;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final Rx<Color> color = Colors.transparent.obs;

  @override
  void onInit() {
    super.onInit();
    _RozetControllerRuntimeX(this as RozetController).loadRozet();
  }
}
