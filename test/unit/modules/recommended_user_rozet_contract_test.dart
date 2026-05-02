import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';

void main() {
  group('Recommended user rozet contract', () {
    test('keeps only sari and mavi badges visible', () {
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('Sarı'),
        'Sarı',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('sari'),
        'Sarı',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('Mavi'),
        'Mavi',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('blue'),
        'Mavi',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('Kırmızı'),
        '',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('Turkuaz'),
        '',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet('Gri'),
        '',
      );
      expect(
        RecommendedUserListController.sanitizeRecommendedUserRozet(''),
        '',
      );
    });

    test('admits only sari and mavi badges to recommended users', () {
      expect(
        RecommendedUserListController.hasAllowedRecommendedUserRozet('Sarı'),
        isTrue,
      );
      expect(
        RecommendedUserListController.hasAllowedRecommendedUserRozet('Mavi'),
        isTrue,
      );
      expect(
        RecommendedUserListController.hasAllowedRecommendedUserRozet('Turkuaz'),
        isFalse,
      );
      expect(
        RecommendedUserListController.hasAllowedRecommendedUserRozet('Kırmızı'),
        isFalse,
      );
      expect(
        RecommendedUserListController.hasAllowedRecommendedUserRozet(''),
        isFalse,
      );
    });
  });
}
