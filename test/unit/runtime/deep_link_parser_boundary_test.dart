import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeepLinkService delegates URI parsing to deep_link_utils', () {
    final source = File(
      'lib/Core/Services/deep_link_service_parse_part.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'ParsedDeepLinkRoute? _performParse(Uri uri) => parseDeepLinkUri(uri)',
      ),
    );
    expect(source, isNot(contains('_ParsedDeepLink')));
    expect(source, isNot(contains('normalizeDeepLinkType')));
    expect(source, isNot(contains('normalizeDeepLinkId')));
    expect(source, isNot(contains('turqapp.com')));
    expect(source, isNot(contains('turqqapp.com')));
  });

  test('education deep links use PrimaryTabRouter for tab routing', () {
    final source = File(
      'lib/Core/Services/deep_link_service_open_part.dart',
    ).readAsStringSync();
    final openStart = source.indexOf('Future<void> _performOpenEducationLink');
    final openEnd =
        source.indexOf('\n  Future<void> _performOpenJob', openStart);

    expect(openStart, isNonNegative);
    expect(openEnd, isNonNegative);

    final openBody = source.substring(openStart, openEnd);

    expect(openBody, contains('PrimaryTabRouter().openEducation()'));
    expect(openBody, contains('educationDeepLinkTabIndexFor(entityId)'));
    expect(openBody, isNot(contains('ensureNavBarController')));
    expect(openBody, isNot(contains('selectedIndex')));
    expect(openBody, isNot(contains('changeIndex(')));
    expect(openBody, isNot(contains("startsWith('scholarship:')")));
    expect(openBody, isNot(contains("startsWith('practiceexam:')")));
    expect(openBody, isNot(contains("startsWith('answerkey:')")));
  });

  test('DeepLinkService delegates direct education-link bypass decisions', () {
    final source = File(
      'lib/Core/Services/deep_link_service_runtime_part.dart',
    ).readAsStringSync();
    final handleStart = source.indexOf('Future<void> handle(Uri uri)');
    final handleEnd = source.indexOf('\n  Future<void> _resolveInitialLink');

    expect(handleStart, isNonNegative);
    expect(handleEnd, isNonNegative);

    final handleBody = source.substring(handleStart, handleEnd);

    expect(handleBody, contains('shouldOpenEducationDeepLinkDirectly'));
    expect(handleBody, isNot(contains("startsWith('question-')")));
    expect(handleBody, isNot(contains("startsWith('scholarship-')")));
    expect(handleBody, isNot(contains("startsWith('practiceexam-')")));
    expect(handleBody, isNot(contains("startsWith('answerkey-')")));
  });
}
