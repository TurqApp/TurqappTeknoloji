part of 'profile_posts_snapshot_repository.dart';

extension ProfilePostsSnapshotRepositoryCodecPart
    on ProfilePostsSnapshotRepository {
  Future<ProfileBuckets> _fetchBuckets(ProfilePostsSnapshotQuery query) async {
    final page = await _profileRepository.fetchPrimaryPage(
      uid: query.userId,
      limit: query.limit,
    );
    return ProfileBuckets(
      all: page.all,
      photos: page.photos,
      videos: page.videos,
      scheduled: page.scheduled,
    );
  }

  Future<ProfileBuckets?> _loadWarmSnapshot(
    ProfilePostsSnapshotQuery query,
  ) {
    return readLocalBuckets(
      userId: query.userId,
      limit: query.limit,
    );
  }

  Map<String, dynamic> _encodeBuckets(ProfileBuckets buckets) {
    Map<String, dynamic> encodePosts(List<PostsModel> posts) {
      return <String, dynamic>{
        'items': posts
            .map((post) => <String, dynamic>{
                  'docID': post.docID,
                  'data': post.toMap(),
                })
            .toList(growable: false),
      };
    }

    return <String, dynamic>{
      'all': encodePosts(buckets.all),
      'photos': encodePosts(buckets.photos),
      'videos': encodePosts(buckets.videos),
      'scheduled': encodePosts(buckets.scheduled),
    };
  }

  ProfileBuckets _decodeBuckets(Map<String, dynamic> json) {
    List<PostsModel> decodePosts(dynamic rawBucket) {
      if (rawBucket is! Map) return const <PostsModel>[];
      final items = rawBucket['items'];
      if (items is! List) return const <PostsModel>[];
      return items
          .whereType<Map>()
          .map((raw) {
            final docId = (raw['docID'] ?? '').toString().trim();
            final data = raw['data'];
            if (docId.isEmpty || data is! Map) return null;
            try {
              return PostsModel.fromMap(
                Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
                docId,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PostsModel>()
          .toList(growable: false);
    }

    return ProfileBuckets(
      all: decodePosts(json['all']),
      photos: decodePosts(json['photos']),
      videos: decodePosts(json['videos']),
      scheduled: decodePosts(json['scheduled']),
    );
  }
}
