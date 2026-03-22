enum MetadataCacheBucket {
  currentUserSummary,
  userProfileSummary,
  authorSummary,
  professionBio,
  followGraphSummary,
  profilePostsBucket,
  avatar,
}

class MetadataCachePolicy {
  static Duration ttlFor(MetadataCacheBucket bucket) {
    switch (bucket) {
      case MetadataCacheBucket.currentUserSummary:
        return const Duration(hours: 24);
      case MetadataCacheBucket.userProfileSummary:
        return const Duration(days: 7);
      case MetadataCacheBucket.authorSummary:
        return const Duration(days: 3);
      case MetadataCacheBucket.professionBio:
        return const Duration(days: 7);
      case MetadataCacheBucket.followGraphSummary:
        return const Duration(hours: 12);
      case MetadataCacheBucket.profilePostsBucket:
        return const Duration(hours: 12);
      case MetadataCacheBucket.avatar:
        return const Duration(days: 30);
    }
  }

  static bool allowStaleRead(MetadataCacheBucket bucket) {
    switch (bucket) {
      case MetadataCacheBucket.currentUserSummary:
        return true;
      case MetadataCacheBucket.userProfileSummary:
        return true;
      case MetadataCacheBucket.authorSummary:
        return true;
      case MetadataCacheBucket.professionBio:
        return true;
      case MetadataCacheBucket.followGraphSummary:
        return false;
      case MetadataCacheBucket.profilePostsBucket:
        return true;
      case MetadataCacheBucket.avatar:
        return true;
    }
  }
}
