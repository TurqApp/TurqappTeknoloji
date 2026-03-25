part of 'profile_repository.dart';

class ProfileBuckets {
  const ProfileBuckets({
    required this.all,
    required this.photos,
    required this.videos,
    required this.scheduled,
  });

  final List<PostsModel> all;
  final List<PostsModel> photos;
  final List<PostsModel> videos;
  final List<PostsModel> scheduled;
}

class ProfilePageResult extends ProfileBuckets {
  const ProfilePageResult({
    required super.all,
    required super.photos,
    required super.videos,
    required super.scheduled,
    required this.lastDoc,
    required this.hasMore,
  });

  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
