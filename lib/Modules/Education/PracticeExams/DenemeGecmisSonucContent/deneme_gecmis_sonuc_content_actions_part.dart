part of 'deneme_gecmis_sonuc_content.dart';

extension DenemeGecmisSonucContentActionsPart on DenemeGecmisSonucContent {
  void _openResultsPreview() {
    Get.to(() => SinavSonuclariPreview(model: model));
  }
}
