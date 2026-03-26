part of 'optical_form_repository.dart';

class OpticalFormRepository extends _OpticalFormRepositoryBase {
  static const Duration _ttl = _OpticalFormRepositoryBase._ttl;
  static const String _prefsPrefix = _OpticalFormRepositoryBase._prefsPrefix;

  OpticalFormRepository({FirebaseFirestore? firestore})
      : super(firestore: firestore);
}
