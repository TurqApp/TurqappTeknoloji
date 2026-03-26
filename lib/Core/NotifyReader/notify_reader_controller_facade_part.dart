part of 'notify_reader_controller.dart';

NotifyReaderController ensureNotifyReaderController({String? tag}) =>
    maybeFindNotifyReaderController(tag: tag) ??
    Get.put(NotifyReaderController(), tag: tag);

NotifyReaderController? maybeFindNotifyReaderController({String? tag}) =>
    Get.isRegistered<NotifyReaderController>(tag: tag)
        ? Get.find<NotifyReaderController>(tag: tag)
        : null;
