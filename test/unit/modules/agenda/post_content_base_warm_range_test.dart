import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_base.dart';

void main() {
  group('resolveFeedSurfaceWarmRange', () {
    test('keeps two behind and four ahead around the centered card', () {
      final range = resolveFeedSurfaceWarmRange(
        centeredIndex: 5,
        listLength: 20,
      );

      expect(range.start, 3);
      expect(range.endExclusive, 10);
    });

    test('clamps at the head of the list', () {
      final range = resolveFeedSurfaceWarmRange(
        centeredIndex: 0,
        listLength: 20,
      );

      expect(range.start, 0);
      expect(range.endExclusive, 5);
    });

    test('clamps at the tail of the list', () {
      final range = resolveFeedSurfaceWarmRange(
        centeredIndex: 8,
        listLength: 10,
      );

      expect(range.start, 6);
      expect(range.endExclusive, 10);
    });
  });
}
