import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/pasaj_feature_gate.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Services/current_user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String scoped(String key) => userScopedKey(key);

  tearDown(() async {
    await CurrentUserService.instance.logout();
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('signed-out pasaj visibility resolves from local snapshot only',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      scoped('pasajVisibility'): <String>['Market'],
    });

    await CurrentUserService.instance.logout();

    final resolved = await loadEffectivePasajVisibility();

    expect(resolved[PasajTabIds.market], isFalse);
    expect(resolved[PasajTabIds.jobFinder], isTrue);
  });

  test('signed-out pasaj tab gate returns local visibility without remote',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      scoped('pasajVisibility'): <String>['Burslar'],
    });

    await CurrentUserService.instance.logout();

    final scholarshipsEnabled = await isPasajTabEnabled(
      PasajTabIds.scholarships,
    );
    final marketEnabled = await isPasajTabEnabled(
      PasajTabIds.market,
    );

    expect(scholarshipsEnabled, isFalse);
    expect(marketEnabled, isTrue);
  });
}
