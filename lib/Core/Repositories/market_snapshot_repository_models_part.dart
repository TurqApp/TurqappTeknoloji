part of 'market_snapshot_repository.dart';

class MarketListingQuery {
  const MarketListingQuery({
    required this.query,
    required this.userId,
    this.limit = ReadBudgetRegistry.marketHomeInitialLimit,
    this.page = 1,
    this.scopeTag = '',
  });

  final String query;
  final String userId;
  final int limit;
  final int page;
  final String scopeTag;

  String buildScopeId(String surfaceKey) => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: limit,
        scopeTag: scopeTag,
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          surfaceKey,
        ),
        qualifiers: <String, Object?>{
          'q': query.trim(),
          'page': page,
        },
      );
}

class MarketOwnerQuery {
  const MarketOwnerQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolveMarketOwnerInitialLimit(limit);

  String buildScopeId(String surfaceKey) => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: effectiveLimit,
        scopeTag: 'owner',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          surfaceKey,
        ),
        qualifiers: <String, Object?>{
          'owner': userId.trim(),
          'limit': effectiveLimit,
        },
      );
}
