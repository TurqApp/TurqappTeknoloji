part of 'scholarships_controller.dart';

ScholarshipsController ensureScholarshipsController({bool permanent = false}) =>
    maybeFindScholarshipsController() ??
    Get.put(ScholarshipsController(), permanent: permanent);

ScholarshipsController? maybeFindScholarshipsController() =>
    Get.isRegistered<ScholarshipsController>()
        ? Get.find<ScholarshipsController>()
        : null;
