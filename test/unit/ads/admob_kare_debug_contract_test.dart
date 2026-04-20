import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdMob debug builds render Google test ads by default', () async {
    final admobSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Ads/admob_kare.dart',
    ).readAsString();
    final unitConfigSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Core/Services/Ads/admob_unit_config_service_facade_part.dart',
    ).readAsString();

    expect(admobSource, contains("'DEBUG_RENDER_ADMOB'"));
    expect(admobSource, contains('defaultValue: true'));
    expect(
      unitConfigSource,
      contains('ca-app-pub-3940256099942544/2934735716'),
    );
    expect(
      unitConfigSource,
      contains('ca-app-pub-3940256099942544/6300978111'),
    );
  });
}
