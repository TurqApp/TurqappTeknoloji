part of 'sinav_sorusu_hazirla_controller.dart';

abstract class _SinavSorusuHazirlaControllerBase extends GetxController {
  _SinavSorusuHazirlaControllerBase({
    required String docID,
    required String sinavTuru,
    required List<String> tumDersler,
    required List<String> derslerinSoruSayilari,
    required Function() complated,
  }) : _state = _buildSinavSorusuHazirlaControllerState(
          docID: docID,
          sinavTuru: sinavTuru,
          tumDersler: tumDersler,
          derslerinSoruSayilari: derslerinSoruSayilari,
          complated: complated,
        );

  final _SinavSorusuHazirlaControllerState _state;
}
