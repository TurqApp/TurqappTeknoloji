part of 'my_statistic_controller.dart';

MyStatisticController ensureMyStatisticController({
  String? tag,
  bool permanent = false,
}) =>
    _ensureMyStatisticController(tag: tag, permanent: permanent);

MyStatisticController? maybeFindMyStatisticController({String? tag}) =>
    _maybeFindMyStatisticController(tag: tag);

MyStatisticController _ensureMyStatisticController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindMyStatisticController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyStatisticController(),
    tag: tag,
    permanent: permanent,
  );
}

MyStatisticController? _maybeFindMyStatisticController({String? tag}) {
  final isRegistered = Get.isRegistered<MyStatisticController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyStatisticController>(tag: tag);
}

String _myStatisticCurrentUid() => CurrentUserService.instance.effectiveUserId;

void _handleMyStatisticControllerInit(MyStatisticController controller) {
  controller._handleOnInit();
}

void _handleMyStatisticControllerClose(MyStatisticController controller) {
  controller._handleOnClose();
}
