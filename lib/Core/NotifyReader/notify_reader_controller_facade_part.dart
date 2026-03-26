part of 'notify_reader_controller.dart';

NotifyReaderController ensureNotifyReaderController({String? tag}) {
  final existing = maybeFindNotifyReaderController(tag: tag);
  if (existing != null) return existing;
  return Get.put(NotifyReaderController(), tag: tag);
}

NotifyReaderController? maybeFindNotifyReaderController({String? tag}) {
  final isRegistered = Get.isRegistered<NotifyReaderController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<NotifyReaderController>(tag: tag);
}
