import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class SavedOpticalFormsController extends GetxController {
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        isLoading.value = false;
        return;
      }
      final savedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "books",
        orderByField: "createdAt",
        descending: true,
        preferCache: true,
        cacheOnly: true,
      );
      if (savedEntries.isNotEmpty) {
        final books = await _bookletRepository.fetchByIds(
          savedEntries.map((e) => e.id).toList(growable: false),
          preferCache: true,
          cacheOnly: true,
        );
        if (books.isNotEmpty) {
          list.assignAll(books);
          isLoading.value = false;
          await getData(silent: true, forceRefresh: true);
          return;
        }
      }
    } catch (_) {}

    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final savedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "books",
        orderByField: "createdAt",
        descending: true,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      final books = await _bookletRepository.fetchByIds(
        savedEntries.map((e) => e.id).toList(growable: false),
        preferCache: true,
      );
      list.assignAll(books);
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}
