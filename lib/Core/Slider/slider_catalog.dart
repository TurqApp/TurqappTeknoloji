import 'package:turqappv2/Themes/app_assets.dart';

class SliderCatalog {
  static List<String> defaultImagesFor(String sliderId) {
    switch (sliderId) {
      case 'denemeler':
        return [
          AppAssets.previous1,
          AppAssets.practice2,
          AppAssets.previous3,
          AppAssets.previous4,
        ];
      case 'online_sinav':
        return [
          AppAssets.practice1,
          AppAssets.practice2,
          AppAssets.practice3,
        ];
      case 'cevap_anahtari':
        return [
          AppAssets.optical1,
          AppAssets.optical2,
          AppAssets.optical3,
        ];
      case 'ozel_ders':
        return [
          AppAssets.tutoring1,
          AppAssets.tutoring2,
          AppAssets.tutoring3,
        ];
      case 'is_bul':
        return [
          AppAssets.job1,
          AppAssets.job2,
          AppAssets.job3,
        ];
      case 'market':
        return [
          AppAssets.job1,
          AppAssets.job2,
          AppAssets.job3,
        ];
      default:
        return const [];
    }
  }
}
