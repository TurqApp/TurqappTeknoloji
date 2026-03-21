import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class BookletPreviewController extends GetxController {
  static BookletPreviewController ensure(
    BookletModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletPreviewController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletPreviewController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final BookletModel model;

  final isBookmarked = false.obs;
  final nickname = ''.obs;
  final avatarUrl = ''.obs;
  final fullName = ''.obs;
  final answerKeys = <AnswerKeySubModel>[].obs;

  BookletPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    final currentUserId = CurrentUserService.instance.userId;
    _loadBookmarkState(currentUserId);
    fetchAnswerKeys();
    fetchUserData();
  }

  Future<void> _loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedDoc = await _subcollectionRepository.getEntry(
        currentUserId,
        subcollection: "books",
        docId: model.docID,
        preferCache: true,
      );
      isBookmarked.value = savedDoc != null;
    } catch (_) {}
  }

  Future<void> fetchAnswerKeys() async {
    try {
      final rawItems = await _bookletRepository.fetchAnswerKeys(
        model.docID,
        preferCache: true,
      );
      final newList = <AnswerKeySubModel>[];
      for (final item in rawItems) {
        final data = Map<String, dynamic>.from(
          (item['data'] as Map?) ?? const <String, dynamic>{},
        );
        final baslik = (data["baslik"] ?? "").toString();
        final rawCevaplar = data["dogruCevaplar"];
        final cevaplar = rawCevaplar is List
            ? rawCevaplar.map((e) => e.toString()).toList()
            : <String>[];
        final sira = data["sira"] is num
            ? data["sira"] as num
            : num.tryParse((data["sira"] ?? "0").toString()) ?? 0;

        newList.add(
          AnswerKeySubModel(
            baslik: baslik,
            docID: (item['id'] ?? '').toString(),
            dogruCevaplar: cevaplar,
            sira: sira,
          ),
        );
      }
      newList.sort((a, b) => a.sira.compareTo(b.sira));
      answerKeys.assignAll(newList);
    } catch (_) {}
  }

  Future<void> fetchUserData() async {
    try {
      final data = await _userSummaryResolver.resolve(
            model.userID,
            preferCache: true,
          ) ??
          _userSummaryResolver.resolveFromMaps(model.userID);
      nickname.value = data.nickname;
      avatarUrl.value = data.avatarUrl;
      fullName.value = data.displayName;
      if (fullName.value.isEmpty) {
        fullName.value = nickname.value;
      }
    } catch (_) {}
  }

  Future<void> toggleBookmark() async {
    final userId = CurrentUserService.instance.userId;
    if (userId.isEmpty) return;

    try {
      final savedDoc = await _subcollectionRepository.getEntry(
        userId,
        subcollection: 'books',
        docId: model.docID,
        preferCache: true,
      );

      if (savedDoc != null) {
        await _subcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: model.docID,
        );
        isBookmarked.value = false;
        return;
      }

      await _subcollectionRepository.upsertEntry(
        userId,
        subcollection: 'books',
        docId: model.docID,
        data: <String, dynamic>{
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      isBookmarked.value = true;
    } catch (_) {}
  }

  void navigateToAnswerKey(BuildContext context, AnswerKeySubModel subModel) {
    Get.to(() => BookletAnswer(model: subModel, anaModel: model));
  }
}
