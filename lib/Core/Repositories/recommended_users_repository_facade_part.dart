part of 'recommended_users_repository.dart';

RecommendedUsersRepository? maybeFindRecommendedUsersRepository() {
  final isRegistered = Get.isRegistered<RecommendedUsersRepository>();
  if (!isRegistered) return null;
  return Get.find<RecommendedUsersRepository>();
}

RecommendedUsersRepository ensureRecommendedUsersRepository() {
  final existing = maybeFindRecommendedUsersRepository();
  if (existing != null) return existing;
  return Get.put(RecommendedUsersRepository(), permanent: true);
}

extension RecommendedUsersRepositoryFacadePart on RecommendedUsersRepository {
  Future<List<RecommendedUserModel>> fetchCandidates({
    int limit = 500,
    bool preferCache = true,
  }) =>
      _fetchCandidatesImpl(
        limit: limit,
        preferCache: preferCache,
      );
}
