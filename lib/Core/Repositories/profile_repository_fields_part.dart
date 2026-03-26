part of 'profile_repository_library.dart';

class _ProfileRepositoryState {
  _ProfileRepositoryState({
    required this.firestore,
    required this.cacheService,
  });

  final FirebaseFirestore firestore;
  final ProfilePostsCacheService cacheService;
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
  ProfilePostsCacheService get _cacheService => _state.cacheService;
  PostRepository get _postRepository => _state.postRepository;
  Map<String, ProfileBuckets> get _memory => _state.memory;
  Map<String, List<PostsModel>> get _archiveMemory => _state.archiveMemory;
  Map<String, PostsModel?> get _latestPostMemory => _state.latestPostMemory;
  Map<String, PostsModel?> get _latestResharePostMemory =>
      _state.latestResharePostMemory;
}
