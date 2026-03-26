part of 'slider_repository.dart';

abstract class _SliderRepositoryBase extends GetxService {
  _SliderRepositoryBase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
}
