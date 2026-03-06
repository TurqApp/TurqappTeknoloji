import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/user_document_schema.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;

  var selection = 0.obs;

  // Text controllers
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController nicknamecontroller = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController resetMailController = TextEditingController();
  TextEditingController resetOtpController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController newPasswordRepeatController = TextEditingController();

  // Focus nodes
  Rx<FocusNode> emailFocus = FocusNode().obs;
  Rx<FocusNode> passwordFocus = FocusNode().obs;
  Rx<FocusNode> nicknameFocus = FocusNode().obs;
  Rx<FocusNode> firstNameFocus = FocusNode().obs;
  Rx<FocusNode> lastNameFocus = FocusNode().obs;
  Rx<FocusNode> phoneNumberFocus = FocusNode().obs;
  Rx<FocusNode> otpFocus = FocusNode().obs;
  Rx<FocusNode> resetMailFocus = FocusNode().obs;
  Rx<FocusNode> resetOtpFocus = FocusNode().obs;
  Rx<FocusNode> newPasswordFocus = FocusNode().obs;
  Rx<FocusNode> newPasswordRepeatFocus = FocusNode().obs;

  var wasSentCode = generateRandomNumber(100000, 999999).obs;
  // Rx values
  var firstName = ''.obs;
  var lastName = ''.obs;
  var phoneNumber = ''.obs;
  var otpCode = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var nicknameAvilable = false.obs;
  var nickname = ''.obs;
  var resetMail = ''.obs;
  var resetOtp = ''.obs;
  var newPassword = "".obs;
  var newPasswordRepeat = "".obs;
  var emailAvilable = false.obs;
  var passwordAvilable = false.obs;
  var wait = false.obs;
  var showPassword = false.obs;

  var isFormValid = false.obs;

  var otpTimer = 120.obs;
  Timer? _timer;

  var resetPhoneNumber = "".obs;
  var resetOldPassword = "".obs;
  var resetUserID = "".obs;
  var otpTimerReset = 120.obs;
  Timer? _timerReset;

  var signInEmail = "".obs;

  Future<void> _restoreAccountIfPendingDeletion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data();
    if (userData == null) return;

    final status = (userData["accountStatus"] ?? "").toString().toLowerCase();
    if (status != "pending_deletion") return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    int? scheduledAtMs;
    final dynamic scheduledRaw = userData["deletionScheduledAt"];
    if (scheduledRaw is Timestamp) {
      scheduledAtMs = scheduledRaw.millisecondsSinceEpoch;
    } else if (scheduledRaw is num) {
      scheduledAtMs = scheduledRaw.toInt();
    }

    // Süresi dolmuşsa (silinme zamanı geçmişse) otomatik geri açma yapma.
    if (scheduledAtMs != null && scheduledAtMs <= nowMs) {
      return;
    }

    // Hesabı yeniden aktif et
    await userRef.set({
      "accountStatus": "active",
      "deletedAccount": false,
      "gizliHesap": false,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Bekleyen silme aksiyonunu iptal işaretle
    try {
      final actionSnap = await userRef
          .collection("account_actions")
          .where("type", isEqualTo: "deletion")
          .where("status", isEqualTo: "pending")
          .limit(1)
          .get();
      if (actionSnap.docs.isNotEmpty) {
        await actionSnap.docs.first.reference.set({
          "status": "cancelled",
          "cancelledAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    // Silme sırasında gizlenen postları geri aç
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("Posts")
        .where("userID", isEqualTo: uid)
        .where("deletedPost", isEqualTo: true)
        .limit(400);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          "deletedPost": false,
          "deletedPostTime": 0,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (snap.docs.length < 400) break;
      query = FirebaseFirestore.instance
          .collection("Posts")
          .where("userID", isEqualTo: uid)
          .where("deletedPost", isEqualTo: true)
          .startAfterDocument(snap.docs.last)
          .limit(400);
    }
  }

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Dinleyiciler
    emailFocus.value.addListener(() => emailFocus.refresh());
    passwordFocus.value.addListener(() => passwordFocus.refresh());
    nicknameFocus.value.addListener(() => nicknameFocus.refresh());
    firstNameFocus.value.addListener(() => firstNameFocus.refresh());
    lastNameFocus.value.addListener(() => lastNameFocus.refresh());
    phoneNumberFocus.value.addListener(() => phoneNumberFocus.refresh());
    resetMailFocus.value.addListener(() => resetMailFocus.refresh());
    otpFocus.value.addListener(() => otpFocus.refresh());
    resetOtpFocus.value.addListener(() => otpFocus.refresh());
    newPasswordFocus.value.addListener(() => newPasswordFocus.refresh());
    newPasswordRepeatFocus.value.addListener(
      () => newPasswordRepeatFocus.refresh(),
    );

    // Text dinleyiciler
    phoneNumberController.addListener(() {
      phoneNumber.value = phoneNumberController.text;
      _validateForm();
    });

    firstNameController.addListener(() {
      firstName.value = firstNameController.text;
      _validateForm();
    });

    lastNameController.addListener(() {
      lastName.value = lastNameController.text;
      _validateForm();
    });

    otpController.addListener(() {
      otpCode.value = otpController.text;
    });

    passwordcontroller.addListener(() {
      password.value = passwordcontroller.text;
    });

    nicknamecontroller.addListener(() {
      nickname.value = nicknamecontroller.text;
    });

    emailcontroller.addListener(() {
      email.value = emailcontroller.text;
    });

    resetMailController.addListener(() {
      resetMail.value = resetMailController.text;
    });

    resetOtpController.addListener(() {
      resetOtp.value = resetOtpController.text;
    });

    newPasswordController.addListener(() {
      newPassword.value = newPasswordController.text;
    });

    newPasswordRepeatController.addListener(() {
      newPasswordRepeat.value = newPasswordRepeatController.text;
    });
  }

  @override
  void onClose() {
    // Text controllers
    emailcontroller.dispose();
    passwordcontroller.dispose();
    nicknamecontroller.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    otpController.dispose();
    resetMailController.dispose();
    resetOtpController.dispose();
    newPasswordController.dispose();
    newPasswordRepeatController.dispose();
    animationController.dispose();
    _timer?.cancel(); // Timer'ı durdur
    super.onClose();
  }

  void _validateForm() {
    final valid = firstNameController.text.trim().length >= 3 &&
        phoneNumberController.text.trim().length == 10 &&
        phoneNumberController.text.trim().startsWith("5");
    isFormValid.value = valid;
  }

  void addToFirestore(BuildContext context) async {
    closeKeyboard(context);
    wait.value = true;
    var accountProvisioned = false;
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('auth-user-null-after-create');
      }
      final uid = authUser.uid;
      final Map<String, dynamic> userDoc = buildInitialUserDocument(
        uid: uid,
        firstName: firstName.value,
        lastName: lastName.value,
        nickname: nickname.value,
        email: email.value,
        phoneNumber: phoneNumber.value,
        password: password.value,
      );

      // Transactional create + increment phone limiter.
      // phoneAccounts read rule kapalıysa fallback ile users dokümanını yine oluştur.
      try {
        await PhoneAccountLimiter().createUserWithLimit(
          uid: uid,
          phone: phoneNumber.value,
          userData: userDoc,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          print(
            '⚠️ phoneAccounts permission-denied, users fallback create uygulanıyor',
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(userDoc, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      // Güvenlik: users dokümanında eksik alan kalmaması için merge ile kesinleştir.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userDoc, SetOptions(merge: true));
      accountProvisioned = true;

      final createdUserSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!createdUserSnap.exists) {
        throw Exception('users-doc-not-created-after-signup');
      }

      const requiredFollowUids = <String>[
        'rlvJgi4VAoO7O78OwrooZc6puPW2',
        'pGlxhtQEVEYeLIa1G2IKhb743E73',
      ];
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final followBatch = FirebaseFirestore.instance.batch();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final adminUid in requiredFollowUids) {
        followBatch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .collection('TakipEdilenler')
              .doc(adminUid),
          {"timeStamp": nowMs},
        );
        followBatch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(adminUid)
              .collection('Takipciler')
              .doc(currentUid),
          {"timeStamp": nowMs},
        );
      }
      await followBatch.commit();
      accountProvisioned = true;

      // 🔥 CRITICAL: Initialize CurrentUserService with new user data
      try {
        print("🔄 CurrentUserService yeni kullanıcı için başlatılıyor...");
        await CurrentUserService.instance.initialize();
        await NotificationService.instance.initialize();

        // Force refresh to load newly created user document
        await CurrentUserService.instance.forceRefresh();
        print("✅ Yeni kullanıcı verisi yüklendi");
      } catch (e) {
        // Kullanıcı oluşturulduysa bu adım hatası onboarding'i bloklamasın.
        print("⚠️ Yeni kullanıcı servis init hatası: $e");
      }

      // 🔥 CRITICAL: Load stories and posts after registration
      try {
        final storyController = Get.find<StoryRowController>();
        print("📚 Hikayeler yükleniyor...");
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
        print(
            "✅ Hikayeler yüklendi: ${storyController.users.length} kullanıcı");
      } catch (e) {
        print("⚠️ Hikaye yükleme hatası: $e");
      }

      // ⚠️ CRITICAL FIX: Ensure AgendaController is created and initialized
      late AgendaController agendaController;
      try {
        // Create or get AgendaController
        if (Get.isRegistered<AgendaController>()) {
          agendaController = Get.find<AgendaController>();
        } else {
          agendaController = Get.put(AgendaController());
        }

        print("📝 Postlar yükleniyor...");

        // Try loading with retry logic
        int retries = 0;
        while (agendaController.agendaList.isEmpty && retries < 3) {
          await agendaController.fetchAgendaBigData(initial: true);
          if (agendaController.agendaList.isEmpty && retries < 2) {
            print("⚠️ Postlar boş, yeniden deneniyor... (${retries + 1}/3)");
            await Future.delayed(const Duration(milliseconds: 500));
          }
          retries++;
        }

        print(
            "✅ Postlar yüklendi: ${agendaController.agendaList.length} gönderi");
      } catch (e) {
        print("⚠️ Post yükleme hatası: $e");
        // If error, still create controller
        agendaController = Get.put(AgendaController());
      }

      // ⚠️ CRITICAL FIX: Start UnreadMessagesController after login
      try {
        if (Get.isRegistered<UnreadMessagesController>()) {
          final unreadController = Get.find<UnreadMessagesController>();
          unreadController.startListeners();
          print("✅ UnreadMessagesController başlatıldı");
        }
      } catch (e) {
        print("⚠️ UnreadMessagesController başlatma hatası: $e");
      }

      wait.value = false;

      // ⚠️ CRITICAL: Give a small delay to ensure all controllers are ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Giris akisinda e-posta dogrulama popup/mesajlarini gosterme.

      Get.off(() => NavBarView());
    } on PhoneAccountLimitReached catch (e) {
      // Rollback newly created auth user to avoid orphaned accounts
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
          'Limit Aşıldı',
          e.message.isNotEmpty
              ? e.message
              : 'Bu telefon numarası için en fazla 5 hesap oluşturulabilir.');
      wait.value = false;
    } catch (e) {
      print('Hata: $e');
      wait.value = false;
      if (accountProvisioned) {
        // Hesap oluştuysa OTP ekranında kalmasın; uygulamaya devam etsin.
        Get.off(() => NavBarView());
        return;
      }
      // users dokümanı hiç oluşmadıysa auth hesabını geri al.
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
        'Kayıt tamamlanamadı',
        'Hesap oluşturma sırasında bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  Future<void> searchEmail() async {
    emailAvilable.value = false;
    if (isValidEmail(emailcontroller.text.trim())) {
      if (FirebaseAuth.instance.currentUser == null) {
        // Giriş öncesi users koleksiyonu auth ister; bloklama yapma.
        emailAvilable.value = true;
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: emailcontroller.text)
          .get();

      emailAvilable.value = snap.docs.isEmpty;
    }
  }

  bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final emailRegex =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> verifyPassword() async {
    final pasword = password.value.toString();
    final containsLetter = RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(pasword);
    final containsNumber = RegExp(r'[0-9]').hasMatch(pasword);
    // En az bir noktalama/simge: yaygın sembol kümesi
    final containsPunct =
        RegExp(r'[!@#\$%\^&*()_+\-=\[\]{};:\\|,.<>\/?~]').hasMatch(pasword);
    final minLen = pasword.length >= 6;

    passwordAvilable.value =
        containsLetter && containsNumber && containsPunct && minLen;
  }

  Future<void> searchNickname() async {
    nicknameAvilable.value = false;

    if (nickname.value.length >= 6) {
      if (FirebaseAuth.instance.currentUser == null) {
        // Giriş öncesi users koleksiyonu auth ister; UI akışını kilitleme.
        nicknameAvilable.value = true;
        return;
      }
      final plainNickname = nickname.value;
      final plainSnap = await FirebaseFirestore.instance
          .collection("users")
          .where("nickname", isEqualTo: plainNickname)
          .get();

      nicknameAvilable.value = plainSnap.docs.isEmpty;
    }
  }

  Future<void> sendOtpCode() async {
    selection.value = 4;
    wasSentCode.value = generateRandomNumber(100000, 999999);
    sendRequest(wasSentCode.value.toString(), phoneNumber.value);
    startOtpTimer(); // TIMER BAŞLAT
  }

  void startOtpTimer() {
    _timer?.cancel(); // Var olan timer varsa iptal et
    otpTimer.value = 120;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimer.value > 0) {
        otpTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendOtpCodeForReset() async {
    wasSentCode.value = generateRandomNumber(100000, 999999);
    sendRequest(wasSentCode.value.toString(), phoneNumber.value);
    startOtpTimerForTimer(); // TIMER BAŞLAT
  }

  void startOtpTimerForTimer() {
    _timerReset?.cancel(); // Var olan timer varsa iptal et
    otpTimerReset.value = 120;

    _timerReset = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimerReset.value > 0) {
        otpTimerReset.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> getResetUserData(String email, String nickname) async {
    resetPhoneNumber.value = "";
    // 1. Önce email ile ara
    final emailSnap = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: email)
        .get();

    if (emailSnap.docs.isNotEmpty) {
      // Email ile eşleşen kayıt bulundu
      final doc = emailSnap.docs.first;
      resetPhoneNumber.value = doc.get("phoneNumber");
      resetOldPassword.value = doc.get("sifre");
      resetUserID.value = doc.id;
      return;
    }

    // 2. Email bulunamadıysa nickname ile ara
    final nickSnap = await FirebaseFirestore.instance
        .collection("users")
        .where("nickname", isEqualTo: nickname)
        .get();

    if (nickSnap.docs.isNotEmpty) {
      final doc = nickSnap.docs.first;
      resetPhoneNumber.value = doc.get("phoneNumber");
      resetOldPassword.value = doc.get("sifre");
      resetUserID.value = doc.id;
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    wait.value = true;
    try {
      // 1. Kullanıcıyı mevcut e-posta ve şifre ile giriş yaptır
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resetMail.value,
        password: newPassword,
      );
      await _restoreAccountIfPendingDeletion();

      // 2. Giriş başarılıysa, şifreyi güncelle
      await userCredential.user!.updatePassword(newPassword);

      FirebaseFirestore.instance
          .collection("users")
          .doc(resetUserID.value)
          .update({"sifre": newPassword});
      print("Şifre başarıyla güncellendi.");

      // 🔥 CRITICAL: Re-initialize CurrentUserService after password reset login
      print("🔄 CurrentUserService yeniden başlatılıyor...");
      await CurrentUserService.instance.initialize();
      await NotificationService.instance.initialize();
      await CurrentUserService.instance.forceRefresh();
      print("✅ CurrentUserService başarıyla yüklendi");

      // 🔥 CRITICAL: Load stories and posts after password reset login
      try {
        final storyController = Get.find<StoryRowController>();
        print("📚 Hikayeler yükleniyor...");
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
        print(
            "✅ Hikayeler yüklendi: ${storyController.users.length} kullanıcı");
      } catch (e) {
        print("⚠️ Hikaye yükleme hatası: $e");
      }

      // ⚠️ CRITICAL FIX: Ensure AgendaController is created and initialized
      late AgendaController agendaController;
      try {
        // Create or get AgendaController
        if (Get.isRegistered<AgendaController>()) {
          agendaController = Get.find<AgendaController>();
        } else {
          agendaController = Get.put(AgendaController());
        }

        print("📝 Postlar yükleniyor...");

        // Try loading with retry logic
        int retries = 0;
        while (agendaController.agendaList.isEmpty && retries < 3) {
          await agendaController.fetchAgendaBigData(initial: true);
          if (agendaController.agendaList.isEmpty && retries < 2) {
            print("⚠️ Postlar boş, yeniden deneniyor... (${retries + 1}/3)");
            await Future.delayed(const Duration(milliseconds: 500));
          }
          retries++;
        }

        print(
            "✅ Postlar yüklendi: ${agendaController.agendaList.length} gönderi");
      } catch (e) {
        print("⚠️ Post yükleme hatası: $e");
        // If error, still create controller
        agendaController = Get.put(AgendaController());
      }

      // ⚠️ CRITICAL FIX: Start UnreadMessagesController after login
      try {
        if (Get.isRegistered<UnreadMessagesController>()) {
          final unreadController = Get.find<UnreadMessagesController>();
          unreadController.startListeners();
          print("✅ UnreadMessagesController başlatıldı");
        }
      } catch (e) {
        print("⚠️ UnreadMessagesController başlatma hatası: $e");
      }

      wait.value = false;

      // ⚠️ CRITICAL: Give a small delay to ensure all controllers are ready
      await Future.delayed(const Duration(milliseconds: 300));

      Get.offAll(() => NavBarView());
      AppSnackbar(
        "Şifreniz Değiştirildi",
        "Şifreniz başarılı bir şekilde değiştirildi ve giriş yapıldı",
      );
    } on FirebaseAuthException catch (e) {
      print("Hata: ${e.code} - ${e.message}");
      AppSnackbar(
        "Bir şeyler ters gitti",
        "Bilinmeyen bir hata oluştu. Hata devam ederse bize ulaşın.",
      );
    } catch (e) {
      print("Beklenmeyen hata: $e");
    }
  }

  Future<void> signIn() async {
    print("Giriş işlemi başlatılıyor...");
    bool authSucceeded = false;
    try {
      print("Email: ${signInEmail.value}");
      print("Şifre: ${'*' * password.value.length}");
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text.contains("@")
            ? emailcontroller.text
            : signInEmail.value,
        password: password.value,
      );
      authSucceeded = true;
      print("Giriş başarılı! Kullanıcı UID: ${userCredential.user?.uid}");
      await _restoreAccountIfPendingDeletion();
      await CurrentUserService.instance.refreshEmailVerificationStatus(
        reloadAuthUser: true,
      );

      // 🔥 CRITICAL: Re-initialize CurrentUserService after login
      print("🔄 CurrentUserService yeniden başlatılıyor...");
      await CurrentUserService.instance.initialize();
      await NotificationService.instance.initialize();

      // Force refresh to ensure latest data
      await CurrentUserService.instance.forceRefresh();
      print("✅ CurrentUserService başarıyla yüklendi");

      // 🔥 CRITICAL: Load stories and posts after fresh login
      try {
        final storyController = Get.find<StoryRowController>();
        print("📚 Hikayeler yükleniyor...");
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
        print(
            "✅ Hikayeler yüklendi: ${storyController.users.length} kullanıcı");
      } catch (e) {
        print("⚠️ Hikaye yükleme hatası: $e");
      }

      // ⚠️ CRITICAL FIX: Ensure AgendaController is created and initialized BEFORE navigation
      late AgendaController agendaController;
      try {
        // Create or get AgendaController
        if (Get.isRegistered<AgendaController>()) {
          agendaController = Get.find<AgendaController>();
        } else {
          agendaController = Get.put(AgendaController());
        }

        print("📝 Postlar yükleniyor...");

        // Try loading with retry logic
        int retries = 0;
        while (agendaController.agendaList.isEmpty && retries < 3) {
          await agendaController.fetchAgendaBigData(initial: true);
          if (agendaController.agendaList.isEmpty && retries < 2) {
            print("⚠️ Postlar boş, yeniden deneniyor... (${retries + 1}/3)");
            await Future.delayed(const Duration(milliseconds: 500));
          }
          retries++;
        }

        print(
            "✅ Postlar yüklendi: ${agendaController.agendaList.length} gönderi");
      } catch (e) {
        print("⚠️ Post yükleme hatası: $e");
        // If error, still create controller with empty list
        agendaController = Get.put(AgendaController());
      }

      // ⚠️ CRITICAL FIX: Start UnreadMessagesController after login
      try {
        if (Get.isRegistered<UnreadMessagesController>()) {
          final unreadController = Get.find<UnreadMessagesController>();
          unreadController.startListeners();
          print("✅ UnreadMessagesController başlatıldı");
        }
      } catch (e) {
        print("⚠️ UnreadMessagesController başlatma hatası: $e");
      }

      wait.value = false;

      // ⚠️ CRITICAL: Give a small delay to ensure all controllers are ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Giris akisinda e-posta dogrulama popup/mesajlarini gosterme.

      Get.offAll(() => NavBarView());
    } on FirebaseAuthException catch (e) {
      print("Giriş hatası oluştu: ${e.code} - ${e.message}");
      wait.value = false;
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = "E-posta veya şifre hatalı. (${e.code})";
          break;
        case 'invalid-email':
          message = "E-posta formatı geçersiz. (${e.code})";
          break;
        case 'too-many-requests':
          message =
              "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin. (${e.code})";
          break;
        case 'network-request-failed':
          message = "İnternet bağlantısı hatası. (${e.code})";
          break;
        case 'user-disabled':
          message = "Bu kullanıcı hesabı devre dışı bırakılmış. (${e.code})";
          break;
        default:
          message =
              "${e.message ?? 'Giriş sırasında hata oluştu.'} (${e.code})";
      }
      AppSnackbar("Giriş yapılamadı", message);
    } catch (e) {
      print("Beklenmeyen bir hata oluştu: $e");
      wait.value = false;
      if (authSucceeded || FirebaseAuth.instance.currentUser != null) {
        // Giriş tamamlandıysa, sonraki hazırlık hataları kullanıcıyı login ekranında tutmasın.
        Get.offAll(() => NavBarView());
        return;
      }
      AppSnackbar("Giriş Başarısız",
          "Sistemlerimizde planlı bir bakım çalışması gerçekleştirilmektedir. Lütfen daha sonra tekrar deneyiniz. Anlayışınız için teşekkür ederiz. (-2)");
    }
  }

  Future<void> nicknameFinder() async {
    try {
      print("yazildi");
      final search = emailcontroller.text.toLowerCase();
      if (search.length < 2) return; // gereksiz sorgu atmayı engelle

      // Auth yoksa users sorgusu permission-denied verir.
      // Email formatı yazıldıysa doğrudan kullan; username araması yapma.
      if (FirebaseAuth.instance.currentUser == null) {
        signInEmail.value = search.contains("@") ? search : "";
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("nickname", isGreaterThanOrEqualTo: search)
          .where("nickname", isLessThan: '$search\uf8ff')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final nickname = snap.docs.first.get("nickname");
        final email = snap.docs.first.get("email");
        print("nickname bulundu: $nickname");
        signInEmail.value = email;
      } else {
        signInEmail.value = "";
        print("nickname bulunamadı");
      }
    } catch (e, stack) {
      print("nicknameFinder hata: $e");
      print("Detaylı StackTrace: $stack");
    }
  }
}
