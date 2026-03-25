part of 'personalized_controller.dart';

PersonalizedController _ensurePersonalizedController({
  required String tag,
  required bool permanent,
}) {
  final existing = PersonalizedController.maybeFind(tag: tag);
  if (existing != null) {
    PersonalizedController._activeTag = tag;
    return existing;
  }
  final created = Get.put(
    PersonalizedController(),
    tag: tag,
    permanent: permanent,
  );
  created.controllerTag = tag;
  PersonalizedController._activeTag = tag;
  return created;
}

PersonalizedController? _maybeFindPersonalizedController({String? tag}) {
  final resolvedTag = (tag ?? PersonalizedController._activeTag)?.trim();
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
  if (PersonalizedController._activeTag == controller.controllerTag) {
    PersonalizedController._activeTag = null;
  }
  controller.scrollController.dispose();
}

extension PersonalizedControllerRuntimePart on PersonalizedController {
  String get _cacheKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      return '${PersonalizedController._cacheKeyPrefix}:guest';
    }
    return '${PersonalizedController._cacheKeyPrefix}:$uid';
  }
}
