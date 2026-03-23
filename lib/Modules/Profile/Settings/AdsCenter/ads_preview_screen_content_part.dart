part of 'ads_preview_screen.dart';

extension AdsPreviewScreenContentPart on _AdsPreviewScreenState {
  Widget _buildPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'ads_center.delivery_simulation'.tr,
          style: const TextStyle(fontFamily: 'MontserratBold', fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildPreviewForm(),
        const SizedBox(height: 16),
        Obx(_buildPreviewResult),
      ],
    );
  }
}
