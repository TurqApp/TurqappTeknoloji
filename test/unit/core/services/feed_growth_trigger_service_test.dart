import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_growth_trigger_service.dart';

void main() {
  group('FeedGrowthTriggerService', () {
    test('estimates viewed count at promo slots from render block and group',
        () {
      expect(
        FeedGrowthTriggerService.estimateViewedCountAtPromo(
          renderBlockIndex: 0,
          renderGroupNumber: 2,
        ),
        6,
      );
      expect(
        FeedGrowthTriggerService.estimateViewedCountAtPromo(
          renderBlockIndex: 0,
          renderGroupNumber: 5,
        ),
        15,
      );
      expect(
        FeedGrowthTriggerService.estimateViewedCountAtPromo(
          renderBlockIndex: 1,
          renderGroupNumber: 3,
        ),
        24,
      );
    });

    test('signals fallback only after next trigger count is reached', () {
      expect(
        FeedGrowthTriggerService.shouldTriggerFallback(
          viewedCount: 6,
          nextTriggerCount: 9,
        ),
        isFalse,
      );
      expect(
        FeedGrowthTriggerService.shouldTriggerFallback(
          viewedCount: 9,
          nextTriggerCount: 9,
        ),
        isTrue,
      );
      expect(
        FeedGrowthTriggerService.shouldTriggerFallback(
          viewedCount: 15,
          nextTriggerCount: 24,
        ),
        isFalse,
      );
    });
  });
}
