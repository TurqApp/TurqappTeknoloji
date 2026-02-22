import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';

class EditorNicknameController extends GetxController {
  final TextEditingController nicknameController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Live kontrol durumu
  final RxBool isChecking = false.obs;
  final RxnBool isAvailable = RxnBool();
  final RxString statusText = ''.obs;
  String _originalNickname = '';
  final RxBool hasUserTyped = false.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchAndSetUserData();
    // Metin değişimini dinle ve debounce ile kontrol et
    nicknameController.addListener(_onTextChanged);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    nicknameController.removeListener(_onTextChanged);
    nicknameController.dispose();
    super.onClose();
  }

  Future<void> fetchAndSetUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        final nickname = data["nickname"] ?? "";
        nicknameController.text = nickname;
        // Orijinal değeri sakla
        _originalNickname = nickname;
        // İlk yüklemede uygunluk durumunu hesapla
        _triggerDebouncedCheck();
      }
    }
  }

  void _onTextChanged() {
    final currentText = nicknameController.text;
    final norm = _normalize(currentText);

    // Kullanıcının gerçekten yazdığını işaretle
    if (currentText.isNotEmpty && currentText != _originalNickname) {
      hasUserTyped.value = true;
    }

    if (currentText != norm) {
      // Kullanıcı yasak karakter girdi ise anında normalize et
      nicknameController.value = nicknameController.value.copyWith(
        text: norm,
        selection: TextSelection.collapsed(offset: norm.length),
      );
    }
    _triggerDebouncedCheck();
  }

  void _triggerDebouncedCheck() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      await checkAvailability();
    });
  }

  String _normalize(String raw) {
    String normalized = raw.trim().toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return normalized;
  }

  String get currentNormalized => _normalize(nicknameController.text);

  bool get canSave {
    final name = currentNormalized;
    final available = isAvailable.value == true;
    final longEnough = name.length >= 6;
    final changed = name != _originalNickname;
    final userHasInteracted = hasUserTyped.value || changed;

    // Eğer kullanıcı bir değişiklik yapmışsa ve kullanıcı adı uygunsa kaydet butonunu aktifleştir
    return available && longEnough && userHasInteracted && !isChecking.value;
  }

  Future<void> checkAvailability() async {
    final name = currentNormalized;
    if (name.isEmpty) {
      isAvailable.value = null;
      statusText.value = '';
      return;
    }
    if (name.length < 6) {
      isAvailable.value = false;
      statusText.value = 'En az 6 karakter olmalı';
      return;
    }

    // Eğer değişmemişse ama kullanıcı etkileşimde bulunmuşsa durumu belirt
    if (name == _originalNickname) {
      isAvailable.value = true;
      if (hasUserTyped.value) {
        statusText.value = 'Mevcut kullanıcı adın';
      } else {
        statusText.value = 'Değişiklik yapmak için düzenle';
      }
      return;
    }

    try {
      isChecking.value = true;
      statusText.value = 'Kontrol ediliyor…';

      // Önce registry kontrolü (usernames/<nickname>)
      final regRef =
          FirebaseFirestore.instance.collection('usernames').doc(name);
      final regSnap = await regRef.get();
      if (regSnap.exists) {
        final data = regSnap.data();
        final owner = data != null ? (data['uid'] as String? ?? '') : '';
        if (owner.isNotEmpty && owner != uid) {
          isAvailable.value = false;
          statusText.value = 'Bu kullanıcı adı alınmış';
          return;
        }
      }

      // Registry yoksa emniyet amaçlı users üzerinde tarama (geçiş süreci için)
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: name)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty && q.docs.first.id != uid) {
        isAvailable.value = false;
        statusText.value = 'Bu kullanıcı adı alınmış';
      } else {
        isAvailable.value = true;
        statusText.value = 'Kullanılabilir';
      }
    } catch (e) {
      isAvailable.value = null;
      statusText.value = 'Kontrol edilemedi';
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> setData() async {
    final normalized = currentNormalized;

    // UI'da normalize edilmiş değeri sabitle
    nicknameController.value = nicknameController.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );

    if (normalized.length < 6) {
      AppSnackbar('Hata', 'Kullanıcı adı en az 6 karakter olmalıdır.');
      return;
    }
    try {
      // Sunucu tarafı garanti: registry + transaction
      final usernames = FirebaseFirestore.instance.collection('usernames');
      final newRef = usernames.doc(normalized);
      final oldRef = _originalNickname.isNotEmpty
          ? usernames.doc(_originalNickname)
          : null;
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        // Yeni ad daha önce rezerve edilmiş mi?
        final newSnap = await tx.get(newRef);
        if (newSnap.exists) {
          final data = newSnap.data();
          final owner = data != null ? (data['uid'] as String? ?? '') : '';
          if (owner != uid) {
            throw Exception('taken');
          }
        }

        // Kullanıcı belgesini güncelle
        tx.update(userDoc, {'nickname': normalized});

        // Registry'de yeni adı rezerve et
        tx.set(newRef, {
          'userID': uid,
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Eski adı serbest bırak (değişiyorsa)
        if (oldRef != null && _originalNickname != normalized) {
          tx.delete(oldRef);
        }
      });

      _originalNickname = normalized;
      Get.back();
    } catch (e) {
      if (e.toString().contains('taken')) {
        AppSnackbar('Hata', 'Bu kullanıcı adı zaten alınmış.');
      } else {
        AppSnackbar('Hata', 'Kullanıcı adı güncellenemedi.');
      }
    }
  }
}
