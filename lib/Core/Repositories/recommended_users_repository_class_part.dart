part of 'recommended_users_repository.dart';

class RecommendedUsersRepository extends GetxService {
  static const String _prefsKeyPrefix = 'recommended_users_repository_v1';
  static const Duration _ttl = Duration(minutes: 10);
  final _state = _RecommendedUsersRepositoryState();

  @override
  void onClose() {
    _handleClose();
    super.onClose();
  }
}
