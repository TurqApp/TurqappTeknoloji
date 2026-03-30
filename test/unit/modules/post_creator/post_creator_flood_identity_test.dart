import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator_flood_identity.dart';

void main() {
  group('post creator flood identity', () {
    test('keeps root doc id on root item', () {
      expect(
        resolvePostCreatorFloodRootDocId(
          '12c93618-5cea-4155-9416-875d429198fd_0',
        ),
        '12c93618-5cea-4155-9416-875d429198fd_0',
      );
    });

    test('normalizes child doc ids back to shared root', () {
      expect(
        resolvePostCreatorFloodRootDocId(
          '12c93618-5cea-4155-9416-875d429198fd_7',
        ),
        '12c93618-5cea-4155-9416-875d429198fd_0',
      );
    });

    test('uses the last underscore as the index separator', () {
      expect(
        resolvePostCreatorFloodRootDocId('series_part_name_3'),
        'series_part_name_0',
      );
    });
  });
}
