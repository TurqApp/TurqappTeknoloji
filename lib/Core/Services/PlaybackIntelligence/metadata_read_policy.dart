import 'metadata_cache_policy.dart';

enum MetadataEntity {
  currentUserSummary,
  userProfileSummary,
  profilePosts,
}

enum MetadataReadSource {
  memory,
  sharedPrefs,
  firestoreCache,
  server,
}

class MetadataReadDecision {
  final MetadataEntity entity;
  final MetadataCacheBucket bucket;
  final List<MetadataReadSource> readOrder;
  final bool allowStaleRead;

  const MetadataReadDecision({
    required this.entity,
    required this.bucket,
    required this.readOrder,
    required this.allowStaleRead,
  });
}

class MetadataReadPolicy {
  static MetadataReadDecision currentUserSummary({
    required bool preferCache,
    required bool cacheOnly,
    required bool forceServer,
  }) {
    if (forceServer) {
      return const MetadataReadDecision(
        entity: MetadataEntity.currentUserSummary,
        bucket: MetadataCacheBucket.currentUserSummary,
        readOrder: <MetadataReadSource>[
          MetadataReadSource.server,
        ],
        allowStaleRead: false,
      );
    }

    if (cacheOnly) {
      return MetadataReadDecision(
        entity: MetadataEntity.currentUserSummary,
        bucket: MetadataCacheBucket.currentUserSummary,
        readOrder: const <MetadataReadSource>[
          MetadataReadSource.memory,
          MetadataReadSource.sharedPrefs,
          MetadataReadSource.firestoreCache,
        ],
        allowStaleRead: MetadataCachePolicy.allowStaleRead(
            MetadataCacheBucket.currentUserSummary),
      );
    }

    if (preferCache) {
      return MetadataReadDecision(
        entity: MetadataEntity.currentUserSummary,
        bucket: MetadataCacheBucket.currentUserSummary,
        readOrder: const <MetadataReadSource>[
          MetadataReadSource.memory,
          MetadataReadSource.sharedPrefs,
          MetadataReadSource.firestoreCache,
          MetadataReadSource.server,
        ],
        allowStaleRead: MetadataCachePolicy.allowStaleRead(
            MetadataCacheBucket.currentUserSummary),
      );
    }

    return const MetadataReadDecision(
      entity: MetadataEntity.currentUserSummary,
      bucket: MetadataCacheBucket.currentUserSummary,
      readOrder: <MetadataReadSource>[
        MetadataReadSource.server,
        MetadataReadSource.memory,
      ],
      allowStaleRead: false,
    );
  }

  static MetadataReadDecision userProfileSummary({
    required bool preferCache,
    required bool cacheOnly,
    required bool forceServer,
  }) {
    if (forceServer) {
      return const MetadataReadDecision(
        entity: MetadataEntity.userProfileSummary,
        bucket: MetadataCacheBucket.userProfileSummary,
        readOrder: <MetadataReadSource>[
          MetadataReadSource.server,
        ],
        allowStaleRead: false,
      );
    }

    if (cacheOnly) {
      return MetadataReadDecision(
        entity: MetadataEntity.userProfileSummary,
        bucket: MetadataCacheBucket.userProfileSummary,
        readOrder: const <MetadataReadSource>[
          MetadataReadSource.memory,
          MetadataReadSource.firestoreCache,
        ],
        allowStaleRead: MetadataCachePolicy.allowStaleRead(
            MetadataCacheBucket.userProfileSummary),
      );
    }

    if (preferCache) {
      return MetadataReadDecision(
        entity: MetadataEntity.userProfileSummary,
        bucket: MetadataCacheBucket.userProfileSummary,
        readOrder: const <MetadataReadSource>[
          MetadataReadSource.memory,
          MetadataReadSource.firestoreCache,
          MetadataReadSource.server,
        ],
        allowStaleRead: MetadataCachePolicy.allowStaleRead(
            MetadataCacheBucket.userProfileSummary),
      );
    }

    return const MetadataReadDecision(
      entity: MetadataEntity.userProfileSummary,
      bucket: MetadataCacheBucket.userProfileSummary,
      readOrder: <MetadataReadSource>[
        MetadataReadSource.server,
        MetadataReadSource.memory,
      ],
      allowStaleRead: false,
    );
  }

  static MetadataReadDecision profilePosts() {
    return MetadataReadDecision(
      entity: MetadataEntity.profilePosts,
      bucket: MetadataCacheBucket.profilePostsBucket,
      readOrder: const <MetadataReadSource>[
        MetadataReadSource.memory,
        MetadataReadSource.sharedPrefs,
        MetadataReadSource.server,
      ],
      allowStaleRead: MetadataCachePolicy.allowStaleRead(
          MetadataCacheBucket.profilePostsBucket),
    );
  }
}
