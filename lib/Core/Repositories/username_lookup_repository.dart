import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

part 'username_lookup_repository_models_part.dart';
part 'username_lookup_repository_facade_part.dart';

class UsernameLookupRepository extends GetxService {
  UsernameLookupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? AppFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _ttl = Duration(minutes: 10);
  final Map<String, _UsernameCacheEntry> _cache =
      <String, _UsernameCacheEntry>{};

  static UsernameLookupRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UsernameLookupRepository>();
    if (!isRegistered) return null;
    return Get.find<UsernameLookupRepository>();
  }

  static UsernameLookupRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UsernameLookupRepository(), permanent: true);
  }
}
