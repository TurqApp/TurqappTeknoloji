part of 'tutoring_repository.dart';

class TutoringRepository extends _TutoringRepositoryBase {
  TutoringRepository({super.firestore});

  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'tutoring_repository_v1';
  static const int _thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
}
