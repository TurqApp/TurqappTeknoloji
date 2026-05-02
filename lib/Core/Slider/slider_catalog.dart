import 'package:turqappv2/Themes/app_assets.dart';

class SliderCatalog {
  static List<String> defaultImagesFor(String sliderId) {
    switch (sliderId) {
      case 'denemeler':
        return [
          AppAssets.livePrevious1,
          AppAssets.livePrevious2,
          AppAssets.livePrevious3,
        ];
      case 'online_sinav':
        return [
          AppAssets.livePractice1,
          AppAssets.livePractice2,
          AppAssets.livePractice3,
        ];
      case 'cevap_anahtari':
        return [
          AppAssets.liveOptical1,
          AppAssets.liveOptical2,
          AppAssets.liveOptical3,
        ];
      case 'ozel_ders':
        return [
          AppAssets.liveTutoring1,
          AppAssets.liveTutoring2,
          AppAssets.liveTutoring3,
          AppAssets.liveTutoring4,
        ];
      case 'is_bul':
        return [
          AppAssets.liveJob1,
          AppAssets.liveJob2,
          AppAssets.liveJob3,
        ];
      case 'market':
        return [
          AppAssets.liveMarket1,
          AppAssets.liveMarket2,
          AppAssets.liveMarket3,
          AppAssets.liveMarket4,
        ];
      default:
        return const [];
    }
  }
}
