import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/PostCreator/CreatorContent/composer_hashtag_utils.dart';

void main() {
  group('composer hashtag utils', () {
    test('finds active hashtag at cursor', () {
      final range = findComposerHashtagRange('Merhaba #kon', 12);
      expect(range, isNotNull);
      expect(range, const TextRange(start: 8, end: 12));
      expect(extractComposerHashtagQuery('Merhaba #kon', 12), 'kon');
    });

    test('returns empty query for standalone hash', () {
      expect(extractComposerHashtagQuery('#', 1), '');
    });

    test('returns null when cursor is outside hashtag token', () {
      expect(extractComposerHashtagQuery('Merhaba dunya', 6), isNull);
    });

    test('replaces active hashtag token with selected trend', () {
      final result = applyComposerHashtagSelection(
        text: 'Bugun #kon yaziyorum',
        cursorOffset: 10,
        hashtag: 'konya',
      );
      expect(result.text, 'Bugun #konya yaziyorum');
      expect(result.cursorOffset, 12);
    });

    test('appends hashtag when there is no active token', () {
      final result = applyComposerHashtagSelection(
        text: 'Bugun guzel',
        cursorOffset: 11,
        hashtag: 'gundem',
      );
      expect(result.text, 'Bugun guzel #gundem ');
      expect(result.cursorOffset, result.text.length);
    });
  });
}
