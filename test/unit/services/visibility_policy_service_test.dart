import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';

void main() {
  group('discovery visibility', () {
    test('badged author is visible to non follower', () {
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{},
          rozet: 'mavi',
          isApproved: false,
          isDeleted: false,
          viewerUserId: 'viewer',
        ),
        isTrue,
      );
    });

    test('approved author is visible to non follower', () {
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{},
          rozet: '',
          isApproved: true,
          isDeleted: false,
          viewerUserId: 'viewer',
        ),
        isTrue,
      );
    });

    test('unbadged author requires follower relation', () {
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{},
          rozet: '',
          isApproved: false,
          isDeleted: false,
          viewerUserId: 'viewer',
        ),
        isFalse,
      );
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{'author'},
          rozet: '',
          isApproved: false,
          isDeleted: false,
          viewerUserId: 'viewer',
        ),
        isTrue,
      );
    });

    test('self remains visible', () {
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{},
          rozet: '',
          isApproved: false,
          isDeleted: false,
          viewerUserId: 'author',
        ),
        isTrue,
      );
    });

    test('deleted author remains hidden', () {
      expect(
        canViewerSeeDiscoverySurfaceAuthor(
          authorUserId: 'author',
          followingIds: const <String>{'author'},
          rozet: 'mavi',
          isApproved: true,
          isDeleted: true,
          viewerUserId: 'viewer',
        ),
        isFalse,
      );
    });
  });
}
