part of 'profile_repository.dart';

class ProfileRepository extends GetxService {
  ProfileRepository({
    FirebaseFirestore? firestore,
    ProfilePostsCacheService? cacheService,
  }) : _state = _ProfileRepositoryState(
          firestore: firestore ?? FirebaseFirestore.instance,
          cacheService: cacheService ?? ProfilePostsCacheService(),
        );

  final _ProfileRepositoryState _state;

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
