part of 'personalized_controller.dart';

PersonalizedController ensurePersonalizedController({
  required String tag,
  bool permanent = false,
}) =>
    _ensurePersonalizedController(tag: tag, permanent: permanent);

PersonalizedController? maybeFindPersonalizedController({String? tag}) =>
    _maybeFindPersonalizedController(tag: tag);

PersonalizedController _ensurePersonalizedController({
  required String tag,
  required bool permanent,
}) {
  final existing = maybeFindPersonalizedController(tag: tag);
  if (existing != null) {
    _activePersonalizedControllerTag = tag;
    return existing;
  }
  final created = Get.put(
    PersonalizedController(),
    tag: tag,
    permanent: permanent,
  );
  created.controllerTag = tag;
  _activePersonalizedControllerTag = tag;
  return created;
}

PersonalizedController? _maybeFindPersonalizedController({String? tag}) {
  final resolvedTag = (tag ?? _activePersonalizedControllerTag)?.trim();
  if (resolvedTag != null && resolvedTag.isNotEmpty) {
    final isRegistered =
        Get.isRegistered<PersonalizedController>(tag: resolvedTag);
    if (!isRegistered) return null;
    return Get.find<PersonalizedController>(tag: resolvedTag);
  }
  final isRegistered = Get.isRegistered<PersonalizedController>();
  if (!isRegistered) return null;
  return Get.find<PersonalizedController>();
}

void _handlePersonalizedControllerInit(PersonalizedController controller) {
  controller._initializeData();
  controller._setupScrollListener();
}

void _handlePersonalizedControllerClose(PersonalizedController controller) {
  if (_activePersonalizedControllerTag == controller.controllerTag) {
    _activePersonalizedControllerTag = null;
  }
  controller.scrollController.dispose();
}

extension PersonalizedControllerRuntimePart on PersonalizedController {
  String get _cacheKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      return '$_personalizedCacheKeyPrefix:guest';
    }
    return '$_personalizedCacheKeyPrefix:$uid';
  }
}
