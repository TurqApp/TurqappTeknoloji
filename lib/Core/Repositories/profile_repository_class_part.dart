part of 'profile_repository.dart';

class ProfileRepository extends GetxService {
  ProfileRepository({
    FirebaseFirestore? firestore,
    ProfilePostsCacheService? cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService ?? ProfilePostsCacheService();

  final FirebaseFirestore _firestore;
  final ProfilePostsCacheService _cacheService;
  final PostRepository _postRepository = PostRepository.ensure();
  final Map<String, ProfileBuckets> _memory = <String, ProfileBuckets>{};
  final Map<String, List<PostsModel>> _archiveMemory =
      <String, List<PostsModel>>{};
  final Map<String, PostsModel?> _latestPostMemory = <String, PostsModel?>{};
  final Map<String, PostsModel?> _latestResharePostMemory =
      <String, PostsModel?>{};

  static ProfileRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfileRepository>();
  }

  static ProfileRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileRepository(), permanent: true);
  }
}
