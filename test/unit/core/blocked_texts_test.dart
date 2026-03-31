import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/block_word_config_service.dart';
import 'package:turqappv2/Core/blocked_texts.dart';

void main() {
  tearDown(() {
    BlockWordConfigService.instance.clearTestOverride();
  });

  test('static blocked word list still matches normalized input', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);
    expect(await kufurKontrolEt('hassiktir'), isTrue);
    expect(await kufurKontrolEt('götünü sikeyim'), isTrue);
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
    expect(await kufurKontrolEt('hassiktir'), isTrue);
  });

  test('removed review terms are no longer blocked by static list', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);

    expect(await kufurKontrolEt('aptal'), isFalse);
    expect(await kufurKontrolEt('anal'), isFalse);
    expect(await kufurKontrolEt('vajina'), isFalse);
    expect(await kufurKontrolEt('verdammt'), isFalse);
    expect(await kufurKontrolEt('allahsız'), isFalse);
    expect(await kufurKontrolEt('gavur'), isFalse);
    expect(await kufurKontrolEt('sürtük'), isFalse);
    expect(await kufurKontrolEt('kime veriyorsun'), isFalse);
    expect(await kufurKontrolEt('gavat'), isFalse);
    expect(await kufurKontrolEt('hure'), isFalse);
    expect(await kufurKontrolEt('şerefsiz'), isFalse);
    expect(await kufurKontrolEt('manyak'), isFalse);
    expect(await kufurKontrolEt('öl geber'), isFalse);
    expect(await kufurKontrolEt('abaza'), isFalse);
    expect(await kufurKontrolEt('saksofon'), isFalse);
    expect(await kufurKontrolEt('allah belanı versin'), isFalse);
    expect(await kufurKontrolEt('topsun'), isFalse);
    expect(await kufurKontrolEt('zibidi'), isFalse);
    expect(await kufurKontrolEt('cibilliyetini'), isFalse);
    expect(await kufurKontrolEt('yalama'), isFalse);
    expect(await kufurKontrolEt('şıllık'), isFalse);
    expect(await kufurKontrolEt('kafam girsin'), isFalse);
    expect(await kufurKontrolEt('mastürbasyon'), isTrue);
    expect(await kufurKontrolEt('porno'), isTrue);
    expect(await kufurKontrolEt('sevişelim'), isTrue);
    expect(await kufurKontrolEt('bitch'), isTrue);
    expect(await kufurKontrolEt('scheisse'), isTrue);
  });

  test('effective blocked list is deduplicated and filtered', () {
    final lowered = kufurler.map((value) => value.toLowerCase()).toList();

    expect(lowered.length, lowered.toSet().length);
    expect(lowered.contains('aptal'), isFalse);
    expect(lowered.contains('abaza'), isFalse);
    expect(lowered.contains('gavur'), isFalse);
    expect(lowered.contains('manyak'), isFalse);
    expect(lowered.contains('allah belanı versin'), isFalse);
    expect(lowered.contains('cibilliyetini'), isFalse);
    expect(lowered.contains('şıllık'), isFalse);
    expect(lowered.contains('mastürbasyon'), isTrue);
    expect(lowered.contains('porno'), isTrue);
    expect(lowered.contains('bitch'), isTrue);
    expect(lowered.contains('orospu'), isTrue);
    expect(lowered.contains('hassiktir'), isTrue);
  });

  test('turkish suffix variations are detected', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);

    expect(await kufurKontrolEt('götünü'), isTrue);
    expect(await kufurKontrolEt('götüne'), isTrue);
    expect(await kufurKontrolEt('götünü sikeyim'), isTrue);
  });

  test('separated and leetspeak variants are detected', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);

    expect(await kufurKontrolEt('g 0 t'), isTrue);
    expect(await kufurKontrolEt('h a s s i k t i r'), isTrue);
  });

  test('matched blocked word is returned for quoted warning copy', () async {
    BlockWordConfigService.instance.setTestOverride(enabled: false);

    final suffixMatch = await kufurEslesmesiniBul('götünü sikeyim');
    final spacedMatch = await kufurEslesmesiniBul('g 0 t');

    expect(suffixMatch?.displayValue, 'götünü');
    expect(spacedMatch?.displayValue, 'g 0 t');
  });

  test('adminConfig allowList can suppress custom false positives', () async {
    BlockWordConfigService.instance.setTestOverride(
      enabled: true,
      words: const <String>['anal'],
      allowWords: const <String>['analiz'],
    );

    expect(await kufurKontrolEt('anal'), isTrue);
    expect(await kufurKontrolEt('analiz'), isFalse);
  });

  test('adminConfig regex patterns are applied on normalized text', () async {
    BlockWordConfigService.instance.setTestOverride(
      enabled: true,
      patterns: const <String>[r'\bg[oö0]+t(?:unu|une|une|un|e|u)?\b'],
    );

    expect(await kufurKontrolEt('g0tunu'), isTrue);
  });
}
