import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('past question roots read bundled asset manifest before storage', () async {
    final source = await File(
      'lib/Core/Repositories/cikmis_sorular_repository_detail_part.dart',
    ).readAsString();
    final pubspec = await File('pubspec.yaml').readAsString();
    final assetFile = File('assets/data/past_questions_manifest.json');

    expect(
      source.contains('assets/data/past_questions_manifest.json'),
      isTrue,
    );
    expect(
      source.contains('rootBundle.loadString(_assetPastQuestionsManifestPath)'),
      isTrue,
    );
    expect(
      pubspec.contains('- assets/data/past_questions_manifest.json'),
      isTrue,
    );
    expect(assetFile.existsSync(), isTrue);
    expect(assetFile.lengthSync(), greaterThan(0));
  });
}
