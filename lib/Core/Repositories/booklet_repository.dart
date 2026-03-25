import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

part 'booklet_repository_query_part.dart';
part 'booklet_repository_action_part.dart';
part 'booklet_repository_models_part.dart';
part 'booklet_repository_cache_part.dart';

class BookletRepository extends GetxService {
  BookletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'booklet_repository_v1';
  final Map<String, _TimedBooklets> _memory = <String, _TimedBooklets>{};
  SharedPreferences? _prefs;

  static BookletRepository? maybeFind() {
    final isRegistered = Get.isRegistered<BookletRepository>();
    if (!isRegistered) return null;
    return Get.find<BookletRepository>();
  }

  static BookletRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(BookletRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _handleBookletRepositoryInit();
  }
}
