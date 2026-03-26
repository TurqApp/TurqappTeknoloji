part of 'profile_repository.dart';

class ProfileRepository extends _ProfileRepositoryBase {
  ProfileRepository({
    FirebaseFirestore? firestore,
    ProfilePostsCacheService? cacheService,
  }) : super(
          firestore: firestore ?? FirebaseFirestore.instance,
          cacheService: cacheService ?? ProfilePostsCacheService(),
        );

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
