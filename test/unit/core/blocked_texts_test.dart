import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/block_word_config_service.dart';
import 'package:turqappv2/Core/blocked_texts.dart';

void main() {
  tearDown(() {
    BlockWordConfigService.instance.clearTestOverride();
  });

  test('static blocked word list still matches normalized input', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);
    expect(await kufurKontrolEt('Aptal!!!'), isTrue);
    expect(await kufurKontrolEt('hassiktir'), isTrue);
  });

  test('adminConfig blockWord words are applied client-side', () async {
    BlockWordConfigService.instance.setTestOverride(
      enabled: true,
      words: const <String>['denemeKelime', 'scheisse'],
    );

    expect(await kufurKontrolEt('denemekelime'), isTrue);
    expect(await kufurKontrolEt('scheisse'), isTrue);
  });

  test('disabled adminConfig blockWord list does not add new blocks', () async {
    BlockWordConfigService.instance.setTestOverride(
      enabled: false,
      words: const <String>['sadeceadmin'],
    );

    expect(await kufurKontrolEt('sadeceadmin'), isFalse);
    expect(await kufurKontrolEt('aptal'), isTrue);
  });
}
