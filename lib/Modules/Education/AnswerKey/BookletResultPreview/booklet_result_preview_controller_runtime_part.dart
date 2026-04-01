part of 'booklet_result_preview_controller.dart';

void _handleBookletResultPreviewInit(
  BookletResultPreviewController controller,
) {
  controller.getData();
}

Future<void> _loadBookletResultPreviewData(
  BookletResultPreviewController controller,
) async {
  controller.anaModel.value = await controller._bookletRepository.fetchById(
    controller.model.kitapcikID,
    preferCache: true,
  );
}

extension BookletResultPreviewControllerRuntimePart
    on BookletResultPreviewController {
  Future<void> getData() => _loadBookletResultPreviewData(this);
}
