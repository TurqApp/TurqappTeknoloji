import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/short_fetch_policy.dart';

void main() {
  group('ShortFetchPolicy', () {
    test('uses the initial page size for cold-start empty lists', () {
      expect(
        ShortFetchPolicy.pageSizeForLoad(
          currentCount: 0,
          initialPageSize: 30,
          bufferedPageSize: 15,
        ),
        30,
      );
    });

    test('keeps the smaller buffered page size after startup', () {
      expect(
        ShortFetchPolicy.pageSizeForLoad(
          currentCount: 15,
          initialPageSize: 30,
          bufferedPageSize: 15,
        ),
        15,
      );
    });

    test('accepts a filled initial block from the larger cold-start page', () {
      expect(
        ShortFetchPolicy.minimumSelectedCountForLoad(
          currentCount: 0,
          initialBlockSize: 15,
          pageSize: 30,
        ),
        15,
      );
    });

    test('requires full pages after startup', () {
      expect(
        ShortFetchPolicy.minimumSelectedCountForLoad(
          currentCount: 30,
          initialBlockSize: 15,
          pageSize: 15,
        ),
        15,
      );
    });

    test('skips the redundant startup refresh after an empty bootstrap', () {
      expect(
        ShortFetchPolicy.shouldRefreshAfterStartupSurface(
          startedEmpty: true,
          seededFreshSession: true,
          hasShorts: true,
          isRefreshing: false,
          isLoading: false,
          allowBackgroundRefresh: true,
        ),
        isFalse,
      );
    });

    test('allows surface refresh for existing short lists', () {
      expect(
        ShortFetchPolicy.shouldRefreshAfterStartupSurface(
          startedEmpty: false,
          seededFreshSession: true,
          hasShorts: true,
          isRefreshing: false,
          isLoading: false,
          allowBackgroundRefresh: true,
        ),
        isTrue,
      );
    });

    test('respects disabled background refresh on startup surface', () {
      expect(
        ShortFetchPolicy.shouldRefreshAfterStartupSurface(
          startedEmpty: false,
          seededFreshSession: true,
          hasShorts: true,
          isRefreshing: false,
          isLoading: false,
          allowBackgroundRefresh: false,
        ),
        isFalse,
      );
    });
  });
}
