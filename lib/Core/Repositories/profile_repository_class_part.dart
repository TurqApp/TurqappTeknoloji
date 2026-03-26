part of 'profile_repository_library.dart';

class ProfileRepository extends _ProfileRepositoryBase {
  ProfileRepository({
    FirebaseFirestore? firestore,
    ProfilePostsCacheService? cacheService,
  }) : super(
          firestore: firestore ?? FirebaseFirestore.instance,
          cacheService: cacheService ?? ProfilePostsCacheService(),
        );
}
