import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_posts_snapshot_repository_models_part.dart';
part 'profile_posts_snapshot_repository_codec_part.dart';
part 'profile_posts_snapshot_repository_facade_part.dart';
part 'profile_posts_snapshot_repository_fields_part.dart';

class ProfilePostsSnapshotRepository extends GetxService {
  static const String _surfaceKey = 'profile_posts_snapshot';

  static ProfilePostsSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfilePostsSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfilePostsSnapshotRepository>();
  }

  static ProfilePostsSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfilePostsSnapshotRepository(), permanent: true);
  }

  final _ProfilePostsSnapshotRepositoryState _state;

  ProfilePostsSnapshotRepository()
      : _state = _ProfilePostsSnapshotRepositoryState() {
    _state.initialize(this);
  }
}
