import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';

part 'draft_service_drafts_part.dart';
part 'draft_service_storage_part.dart';

class PostDraft {
  final String id;
  final String text;
  final List<String> imagePaths;
  final String? videoPath;
  final String location;
  final String gif;
  final bool commentEnabled;
  final int sharePrivacy;
  final DateTime lastModified;
  final DateTime? scheduledDate;

  PostDraft({
    required this.id,
    required this.text,
    required this.imagePaths,
    this.videoPath,
    required this.location,
    required this.gif,
    required this.commentEnabled,
    required this.sharePrivacy,
    required this.lastModified,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
        'location': location,
        'gif': gif,
        'commentEnabled': commentEnabled,
        'sharePrivacy': sharePrivacy,
        'lastModified': lastModified.millisecondsSinceEpoch,
        'scheduledDate': scheduledDate?.millisecondsSinceEpoch,
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) => PostDraft(
        id: json['id'],
        text: json['text'],
        imagePaths: List<String>.from(json['imagePaths']),
        videoPath: json['videoPath'],
        location: json['location'],
        gif: json['gif'],
        commentEnabled: json['commentEnabled'],
        sharePrivacy: json['sharePrivacy'],
        lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified']),
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['scheduledDate'])
            : null,
      );

  bool get isEmpty =>
      text.trim().isEmpty &&
      imagePaths.isEmpty &&
      videoPath == null &&
      gif.isEmpty;

  bool get hasMedia =>
      imagePaths.isNotEmpty || videoPath != null || gif.isNotEmpty;

  String get previewText {
    if (text.isNotEmpty) {
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    if (hasMedia) {
      final mediaCount = imagePaths.length +
          (videoPath != null ? 1 : 0) +
          (gif.isNotEmpty ? 1 : 0);
      return '$mediaCount medya dosyası';
    }
    return 'Boş taslak';
  }
}

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
