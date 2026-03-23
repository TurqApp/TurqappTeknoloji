part of 'sinav_sorusu_hazirla.dart';

extension SinavSorusuHazirlaShellPart on _SinavSorusuHazirlaState {
  Widget _buildSinavSorusuHazirlaBody() {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              BackButtons(text: 'tests.prepare_questions'.tr),
              Expanded(child: _buildSinavSorusuHazirlaContent()),
            ],
          ),
        ],
      ),
    );
  }
}
