part of 'sinav_sonuclarim.dart';

extension SinavSonuclarimShellPart on _SinavSonuclarimState {
  Widget _buildSinavSonuclarimBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'practice.results_title'.tr),
          Expanded(child: _buildSinavSonuclarimContent()),
        ],
      ),
    );
  }
}
