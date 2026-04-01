part of 'profile_repository_library.dart';

class ProfileRepository extends _ProfileRepositoryBase {
  ProfileRepository({
    FirebaseFirestore? firestore,
  }) : super(
          firestore: firestore ?? FirebaseFirestore.instance,
        );
}

abstract class _ProfileRepositoryBase extends GetxService {
  _ProfileRepositoryBase({
    required FirebaseFirestore firestore,
  }) : _state = _ProfileRepositoryState(
          firestore: firestore,
        );

  final _ProfileRepositoryState _state;
}

class ProfileBuckets {
  const ProfileBuckets({
    required this.all,
    required this.photos,
    required this.videos,
    required this.reshares,
    required this.scheduled,
  });

  final List<PostsModel> all;
  final List<PostsModel> photos;
  final List<PostsModel> videos;
  final List<PostsModel> reshares;
  final List<PostsModel> scheduled;
}

class ProfilePageResult extends ProfileBuckets {
  const ProfilePageResult({
    required super.all,
    required super.photos,
    required super.videos,
    required super.reshares,
    required super.scheduled,
    required this.lastDoc,
    required this.hasMore,
  });

  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class _ProfileRepositoryState {
  _ProfileRepositoryState({
    required this.firestore,
  });

  final FirebaseFirestore firestore;
  final PostRepository postRepository = PostRepository.ensure();
  final Map<String, ProfileBuckets> memory = <String, ProfileBuckets>{};
  final Map<String, List<PostsModel>> archiveMemory =
      <String, List<PostsModel>>{};
  final Map<String, PostsModel?> latestPostMemory = <String, PostsModel?>{};
  final Map<String, PostsModel?> latestResharePostMemory =
      <String, PostsModel?>{};
}

extension ProfileRepositoryFieldsPart on ProfileRepository {
  FirebaseFirestore get _firestore => _state.firestore;
  PostRepository get _postRepository => _state.postRepository;
  Map<String, ProfileBuckets> get _memory => _state.memory;
  Map<String, List<PostsModel>> get _archiveMemory => _state.archiveMemory;
  Map<String, PostsModel?> get _latestPostMemory => _state.latestPostMemory;
  Map<String, PostsModel?> get _latestResharePostMemory =>
      _state.latestResharePostMemory;
}
