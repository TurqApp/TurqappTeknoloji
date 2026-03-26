part of 'profile_repository_library.dart';

abstract class _ProfileRepositoryBase extends GetxService {
  _ProfileRepositoryBase({
    required FirebaseFirestore firestore,
    required ProfilePostsCacheService cacheService,
  }) : _state = _ProfileRepositoryState(
          firestore: firestore,
          cacheService: cacheService,
        );

  final _ProfileRepositoryState _state;
}
