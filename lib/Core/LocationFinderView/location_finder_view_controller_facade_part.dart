part of 'location_finder_view_controller.dart';

LocationFinderViewController ensureLocationFinderViewController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindLocationFinderViewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    LocationFinderViewController(),
    tag: tag,
    permanent: permanent,
  );
}

LocationFinderViewController? maybeFindLocationFinderViewController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<LocationFinderViewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<LocationFinderViewController>(tag: tag);
}
