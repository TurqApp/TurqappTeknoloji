import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  final RxList<PostDraft> _drafts = <PostDraft>[].obs;
  final RxBool _autoSaveEnabled = true.obs;
  final RxInt _autoSaveInterval = 30.obs; // seconds

  static const String _draftsKey = 'post_drafts';
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
  }

  /// Save draft automatically
  Future<String> saveDraft({
    required String text,
    required List<File> images,
    File? video,
    required String location,
    required String gif,
    required bool commentEnabled,
    required int sharePrivacy,
    DateTime? scheduledDate,
    String? existingDraftId,
  }) async {
    // Don't save empty drafts
    if (text.trim().isEmpty && images.isEmpty && video == null && gif.isEmpty) {
      return '';
    }

    final draftId =
        existingDraftId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Save media files to app directory
    final imagePaths = await _saveMediaFiles(images, draftId, 'images');
    final videoPath =
        video != null ? await _saveMediaFile(video, draftId, 'video') : null;

    final draft = PostDraft(
      id: draftId,
      text: text,
      imagePaths: imagePaths,
      videoPath: videoPath,
      location: location,
      gif: gif,
      commentEnabled: commentEnabled,
      sharePrivacy: sharePrivacy,
      lastModified: DateTime.now(),
      scheduledDate: scheduledDate,
    );

    // Update existing or add new
    final existingIndex = _drafts.indexWhere((d) => d.id == draftId);
    if (existingIndex != -1) {
      _drafts[existingIndex] = draft;
    } else {
      _drafts.add(draft);
    }

    // Keep only latest drafts
    if (_drafts.length > _maxDrafts) {
      _drafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final removedDrafts = _drafts.sublist(_maxDrafts);

      // Clean up media files of removed drafts
      for (final removedDraft in removedDrafts) {
        await _cleanupDraftMedia(removedDraft);
      }

      _drafts.removeRange(_maxDrafts, _drafts.length);
    }

    await _saveDraftsToStorage();
    return draftId;
  }

  /// Load draft
  PostDraft? loadDraft(String draftId) {
    return _drafts.firstWhereOrNull((d) => d.id == draftId);
  }

  /// Delete draft
  Future<void> deleteDraft(String draftId) async {
    final draft = _drafts.firstWhereOrNull((d) => d.id == draftId);
    if (draft != null) {
      await _cleanupDraftMedia(draft);
      _drafts.removeWhere((d) => d.id == draftId);
      await _saveDraftsToStorage();
    }
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    for (final draft in _drafts) {
      await _cleanupDraftMedia(draft);
    }
    _drafts.clear();
    await _saveDraftsToStorage();
  }

  /// Get drafts sorted by last modified
  List<PostDraft> getDraftsSorted() {
    final sortedDrafts = List<PostDraft>.from(_drafts);
    sortedDrafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return sortedDrafts;
  }

  /// Auto-save settings
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, enabled);
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    _autoSaveInterval.value = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_save_interval', seconds);
  }

  /// Save media files to app directory
  Future<List<String>> _saveMediaFiles(
      List<File> files, String draftId, String type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftDir = Directory(p.join(appDir.path, 'drafts', draftId, type));

    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }

    final savedPaths = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final extension = p.extension(file.path);
      final targetPath = p.join(draftDir.path, '$i$extension');

      await file.copy(targetPath);
      savedPaths.add(targetPath);
    }

    return savedPaths;
  }

  /// Save single media file
  Future<String> _saveMediaFile(File file, String draftId, String type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftDir = Directory(p.join(appDir.path, 'drafts', draftId, type));

    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }

    final extension = p.extension(file.path);
    final targetPath = p.join(draftDir.path, 'media$extension');

    await file.copy(targetPath);
    return targetPath;
  }

  /// Cleanup draft media files
  Future<void> _cleanupDraftMedia(PostDraft draft) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final draftDir = Directory(p.join(appDir.path, 'drafts', draft.id));

      if (await draftDir.exists()) {
        await draftDir.delete(recursive: true);
      }
    } catch (_) {
    }
  }

  /// Save drafts to storage
  Future<void> _saveDraftsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = _drafts.map((draft) => draft.toJson()).toList();
    await prefs.setString(_draftsKey, jsonEncode(draftsJson));
  }

  /// Load drafts from storage
  Future<void> _loadDraftsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsString = prefs.getString(_draftsKey);

    if (draftsString != null) {
      final draftsJson = jsonDecode(draftsString) as List;
      _drafts.assignAll(
        draftsJson.map((item) => PostDraft.fromJson(item)).toList(),
      );
    }
  }

  /// Load settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSaveEnabled.value = prefs.getBool(_autoSaveKey) ?? true;
    _autoSaveInterval.value = prefs.getInt('auto_save_interval') ?? 30;
  }

  /// Get draft statistics
  Map<String, dynamic> getDraftStats() {
    final now = DateTime.now();
    final today =
        _drafts.where((d) => now.difference(d.lastModified).inDays == 0).length;
    final thisWeek =
        _drafts.where((d) => now.difference(d.lastModified).inDays < 7).length;

    return {
      'total': _drafts.length,
      'today': today,
      'thisWeek': thisWeek,
      'withMedia': _drafts.where((d) => d.hasMedia).length,
      'textOnly': _drafts.where((d) => !d.hasMedia && d.text.isNotEmpty).length,
    };
  }

  /// Export draft as shareable format
  Map<String, dynamic> exportDraft(String draftId) {
    final draft = loadDraft(draftId);
    if (draft == null) return {};

    return {
      'text': draft.text,
      'location': draft.location,
      'hasImages': draft.imagePaths.isNotEmpty,
      'hasVideo': draft.videoPath != null,
      'hasGif': draft.gif.isNotEmpty,
      'lastModified': draft.lastModified.toIso8601String(),
    };
  }
}
