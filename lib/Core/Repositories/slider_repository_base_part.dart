part of 'slider_repository_library.dart';

abstract class _SliderRepositoryBase extends GetxService {
  _SliderRepositoryBase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
}
