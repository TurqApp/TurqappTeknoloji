import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:turqappv2/Themes/app_assets.dart';

void main() {
  test('managed education sliders use bundled live asset defaults', () {
    expect(
      SliderCatalog.defaultImagesFor('market'),
      <String>[
        AppAssets.liveMarket1,
        AppAssets.liveMarket2,
        AppAssets.liveMarket3,
        AppAssets.liveMarket4,
      ],
    );
    expect(
      SliderCatalog.defaultImagesFor('is_bul'),
      <String>[
        AppAssets.liveJob1,
        AppAssets.liveJob2,
        AppAssets.liveJob3,
      ],
    );
    expect(
      SliderCatalog.defaultImagesFor('ozel_ders'),
      <String>[
        AppAssets.liveTutoring1,
        AppAssets.liveTutoring2,
        AppAssets.liveTutoring3,
        AppAssets.liveTutoring4,
      ],
    );
    expect(
      SliderCatalog.defaultImagesFor('cevap_anahtari'),
      <String>[
        AppAssets.liveOptical1,
        AppAssets.liveOptical2,
        AppAssets.liveOptical3,
      ],
    );
    expect(
      SliderCatalog.defaultImagesFor('online_sinav'),
      <String>[
        AppAssets.livePractice1,
        AppAssets.livePractice2,
        AppAssets.livePractice3,
      ],
    );
    expect(
      SliderCatalog.defaultImagesFor('denemeler'),
      <String>[
        AppAssets.livePrevious1,
        AppAssets.livePrevious2,
        AppAssets.livePrevious3,
      ],
    );
  });
}
