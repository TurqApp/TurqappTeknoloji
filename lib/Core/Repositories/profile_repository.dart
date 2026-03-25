import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';

import '../../Core/Services/profile_posts_cache_service.dart';
import '../../Models/posts_model.dart';
import 'post_repository.dart';

part 'profile_repository_cache_part.dart';
part 'profile_repository_facade_part.dart';
part 'profile_repository_models_part.dart';
part 'profile_repository_query_part.dart';

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
