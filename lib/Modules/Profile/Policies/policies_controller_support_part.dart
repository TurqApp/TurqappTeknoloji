part of 'policies_controller.dart';

PoliciesController _ensurePoliciesController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindPoliciesController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PoliciesController(),
    tag: tag,
    permanent: permanent,
  );
}

PoliciesController? _maybeFindPoliciesController({String? tag}) {
  final isRegistered = Get.isRegistered<PoliciesController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PoliciesController>(tag: tag);
}
