import 'package:turqappv2/Core/Services/AppPolicy/surface_policy_registry.dart';

import 'cache_first_policy.dart';

class CacheFirstPolicyRegistry {
  const CacheFirstPolicyRegistry._();

  static const int defaultSchemaVersion =
      SurfacePolicyRegistry.defaultSchemaVersion;
  static const int feedHomeSchemaVersion =
      SurfacePolicyRegistry.feedHomeSchemaVersion;
  static const int shortHomeSchemaVersion =
      SurfacePolicyRegistry.shortHomeSchemaVersion;
  static const int profilePostsSchemaVersion =
      SurfacePolicyRegistry.profilePostsSchemaVersion;
  static const int notificationsInboxSchemaVersion =
      SurfacePolicyRegistry.notificationsInboxSchemaVersion;
  static const int listingSnapshotSchemaVersion =
      SurfacePolicyRegistry.listingSnapshotSchemaVersion;

  static CacheFirstPolicy policyForSurface(String surfaceKey) {
    return SurfacePolicyRegistry.policyForSnapshotSurface(surfaceKey)
        .cachePolicy;
  }

  static int schemaVersionForSurface(String surfaceKey) {
    return SurfacePolicyRegistry.policyForSnapshotSurface(surfaceKey)
        .schemaVersion;
  }
}
