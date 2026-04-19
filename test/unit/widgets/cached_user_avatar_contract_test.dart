import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';

void main() {
  group('CachedUserAvatar bootstrap helpers', () {
    test('prefers direct image url before cached profile and summary', () {
      final url = resolveCachedUserAvatarBootstrapUrl(
        directImageUrl: 'https://cdn.turqapp.com/direct.jpg',
        userId: 'u1',
        currentUserId: 'u2',
        currentAvatarUrl: 'https://cdn.turqapp.com/current.jpg',
        currentStreamAvatarUrl: 'https://cdn.turqapp.com/stream.jpg',
        cachedProfileAvatarUrl: 'https://cdn.turqapp.com/profile.jpg',
        cachedSummaryAvatarUrl: 'https://cdn.turqapp.com/summary.jpg',
      );

      expect(url, 'https://cdn.turqapp.com/direct.jpg');
    });

    test('uses cached profile avatar when direct image is absent', () {
      final url = resolveCachedUserAvatarBootstrapUrl(
        userId: 'u1',
        currentUserId: 'u2',
        currentAvatarUrl: '',
        currentStreamAvatarUrl: '',
        cachedProfileAvatarUrl: 'https://cdn.turqapp.com/profile.jpg',
        cachedSummaryAvatarUrl: 'https://cdn.turqapp.com/summary.jpg',
      );

      expect(url, 'https://cdn.turqapp.com/profile.jpg');
    });

    test('keeps pending placeholder only when a concrete avatar source exists',
        () {
      expect(
        shouldDeferCachedUserAvatarPlaceholder(
          bootstrapSettled: false,
          bootstrapInFlight: true,
          resolvedFilePath: '',
          resolvedUrl: '',
          directImageUrl: '',
        ),
        isFalse,
      );

      expect(
        shouldDeferCachedUserAvatarPlaceholder(
          bootstrapSettled: false,
          bootstrapInFlight: true,
          resolvedFilePath: '',
          resolvedUrl: 'https://cdn.turqapp.com/profile.jpg',
          directImageUrl: '',
        ),
        isTrue,
      );
    });
  });
}
