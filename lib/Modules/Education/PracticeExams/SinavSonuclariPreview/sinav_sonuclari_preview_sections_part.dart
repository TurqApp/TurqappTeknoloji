part of 'sinav_sonuclari_preview.dart';

extension SinavSonuclariPreviewSectionsPart on _SinavSonuclariPreviewState {
  Widget _buildEmptyState(String text) {
    return AppStateView.empty(
      title: text,
      icon: Icons.error_outline,
    );
  }

  Widget _buildResultsTable() {
    return Obx(() {
      if (controller.isInitialized.value && controller.dersVeSonuclar.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'practice.preview_no_results'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 15,
              top: 100,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'practice.lesson_header'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                _buildResultHeader('tests.correct'.tr),
                _buildResultHeader('tests.wrong'.tr),
                _buildResultHeader('tests.blank'.tr),
                _buildResultHeader('tests.net'.tr),
              ],
            ),
          ),
          for (final item in controller.dersVeSonuclar)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.ders, style: TextStyles.medium15Black),
                  ),
                  _buildResultCell(item.dogru.toString()),
                  _buildResultCell(item.yanlis.toString()),
                  _buildResultCell(item.bos.toString()),
                  _buildResultCell(item.net.toString()),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildResultHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _buildResultCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyles.regular15Black,
      ),
    );
  }
}
