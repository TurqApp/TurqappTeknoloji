part of 'short_repository.dart';

class ShortRepository extends GetxService {
  ShortRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
}
