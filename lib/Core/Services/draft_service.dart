import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';

part 'draft_service_models_part.dart';
part 'draft_service_drafts_part.dart';
part 'draft_service_storage_part.dart';

class DraftService extends GetxController {
  static DraftService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DraftService());
  }

  static DraftService? maybeFind() {
    final isRegistered = Get.isRegistered<DraftService>();
    if (!isRegistered) return null;
    return Get.find<DraftService>();
  }

  final RxList<PostDraft> _drafts = <PostDraft>[].obs;
  final RxBool _autoSaveEnabled = true.obs;
  final RxInt _autoSaveInterval = 30.obs; // seconds
  StreamSubscription<User?>? _authSub;

  static const String _draftsKeyPrefix = 'post_drafts';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const int _maxDrafts = 20;

  List<PostDraft> get drafts => _drafts;
  bool get autoSaveEnabled => _autoSaveEnabled.value;
  int get autoSaveInterval => _autoSaveInterval.value;

  @override
  void onInit() {
    super.onInit();
    _loadDraftsFromStorage();
    _loadSettings();
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_loadDraftsFromStorage());
    });
  }

  String get _activeDraftsKey {
    return userScopedKey(_draftsKeyPrefix);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}
