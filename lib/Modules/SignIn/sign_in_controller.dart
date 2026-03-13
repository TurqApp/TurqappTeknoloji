import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/user_document_schema.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSubdocRepository _userSubdocRepository =
      UserSubdocRepository.ensure();
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
  var showNewPassword = false.obs;
  var showNewPasswordRepeat = false.obs;

  var isFormValid = false.obs;

  var otpTimer = 0.obs;
  Timer? _timer;
  var signupCodeRequested = false.obs;
  var otpRequestInFlight = false.obs;

  var resetPhoneNumber = "".obs;
  var resetOldPassword = "".obs;
  var resetUserID = "".obs;
  var otpTimerReset = 0.obs;
  Timer? _timerReset;
  var resetCodeRequested = false.obs;

  var signInEmail = "".obs;

  void _ensureFeedTabSelected() {
    if (Get.isRegistered<NavBarController>()) {
      Get.find<NavBarController>().selectedIndex.value = 0;
      return;
    }
    final nav = Get.put(NavBarController());
    nav.selectedIndex.value = 0;
  }

  String _formatSeconds(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _clearSessionCachesAfterAccountSwitch() async {
    try {
      if (Get.isRegistered<UserProfileCacheService>()) {
        await Get.find<UserProfileCacheService>().clearAll();
      }
      PostContentController.clearUserProfileCache();
      if (Get.isRegistered<StoryRowController>()) {
        await Get.find<StoryRowController>().clearSessionCache();
      }
      if (Get.isRegistered<AgendaController>()) {
        final agenda = Get.find<AgendaController>();
        agenda.agendaList.clear();
        await agenda.refreshAgenda();
      }
    } catch (e) {
      print('⚠️ Session cache clear error: $e');
    }
  }

  Future<void> _restoreAccountIfPendingDeletion() async {
    await CurrentUserService.instance.restorePendingDeletionIfNeededForCurrentUser();
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
        firstName: firstName.value,
        lastName: lastName.value,
        nickname: nickname.value,
        email: email.value,
        phoneNumber: phoneNumber.value,
      );
      final userSubdocs = buildInitialUserSubdocuments(userDoc: userDoc);

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
          await _userRepository.upsertUserFields(uid, userDoc);
        } else {
          rethrow;
        }
      }

      // Güvenlik: users dokümanında eksik alan kalmaması için merge ile kesinleştir.
      await _userRepository.upsertUserFields(uid, userDoc);
      final subdocWrites = <Future<void>>[];
      userSubdocs.forEach((path, data) {
        final segments = path.split('/');
        if (segments.length == 2) {
          subdocWrites.add(
            _userSubdocRepository.setDoc(
              uid,
              collection: segments[0],
              docId: segments[1],
              data: Map<String, dynamic>.from(data),
              merge: true,
            ),
          );
        }
      });
      await Future.wait(subdocWrites);
      accountProvisioned = true;

      final createdUserData =
          await _userRepository.getUserRaw(uid, preferCache: false);
      if (createdUserData == null) {
        throw Exception('users-doc-not-created-after-signup');
      }

      await MandatoryFollowService.instance.enforceForCurrentUser();
      accountProvisioned = true;

      // 🔥 CRITICAL: Initialize CurrentUserService with new user data
      try {
        print("🔄 CurrentUserService yeni kullanıcı için başlatılıyor...");
        await CurrentUserService.instance.initialize();
        await NotificationService.instance.initialize();
        await _clearSessionCachesAfterAccountSwitch();

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

        await agendaController.refreshAgenda();

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

      _ensureFeedTabSelected();
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
    } on UsernameAlreadyTaken catch (e) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
        'Kullanıcı adı kullanımda',
        e.message.isNotEmpty
            ? e.message
            : 'Lütfen farklı bir kullanıcı adı seç.',
      );
      wait.value = false;
    } catch (e) {
      print('Hata: $e');
      wait.value = false;
      if (accountProvisioned) {
        // Hesap oluştuysa OTP ekranında kalmasın; uygulamaya devam etsin.
        _ensureFeedTabSelected();
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
      final exists = await _userRepository.emailExists(
        emailcontroller.text,
        preferCache: true,
      );
      emailAvilable.value = !exists;
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
      final usernameLower = nickname.value.trim().toLowerCase();
      if (usernameLower.isEmpty) {
        nicknameAvilable.value = false;
        return;
      }
      if (FirebaseAuth.instance.currentUser == null) {
        // Auth yoksa sorgu yok; akış bloklanmasın.
        nicknameAvilable.value = true;
        return;
      }
      nicknameAvilable.value = await _userRepository.usernameLowerAvailable(
        usernameLower,
        preferCache: true,
      );
    }
  }

  Future<void> sendOtpCode() async {
    if (otpRequestInFlight.value) return;
    if (signupCodeRequested.value && otpTimer.value > 0) {
      AppSnackbar(
        "Bekleyin",
        "Yeni kod için ${otpTimer.value} saniye bekleyin.",
      );
      return;
    }

    final phone = phoneNumber.value.trim();
    if (phone.length != 10 || !phone.startsWith('5')) {
      AppSnackbar(
        "Geçersiz Telefon",
        "Lütfen 5 ile başlayan 10 haneli telefon numarası girin.",
      );
      return;
    }

    selection.value = 4;
    otpRequestInFlight.value = true;
    wasSentCode.value = generateRandomNumber(100000, 999999);
    sendRequest(wasSentCode.value.toString(), phone);
    startOtpTimer(); // TIMER BAŞLAT
    signupCodeRequested.value = true;
    otpRequestInFlight.value = false;
  }

  void startOtpTimer() {
    _timer?.cancel(); // Var olan timer varsa iptal et
    otpTimer.value = 300;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimer.value > 0) {
        otpTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendOtpCodeForReset() async {
    final targetEmail = resetMailController.text.trim().toLowerCase();
    if (!isValidEmail(targetEmail)) {
      AppSnackbar("Geçersiz E-posta", "Lütfen geçerli bir e-posta girin.");
      return;
    }
    if (resetCodeRequested.value && otpTimerReset.value > 0) {
      AppSnackbar(
        "Bekleyin",
        "Yeni kod için ${otpTimerReset.value} saniye bekleyin.",
      );
      return;
    }

    wait.value = true;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendPasswordResetSmsCode')
          .call({
        "email": targetEmail,
      });
      startOtpTimerForTimer(); // TIMER BAŞLAT
      resetCodeRequested.value = true;
      AppSnackbar(
        "Kod Gönderildi",
        "SMS gönderildi. Kod 60 saniye geçerli.",
      );
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-argument':
          message = "Geçerli bir e-posta ve 6 haneli kod gerekli.";
          break;
        case 'not-found':
          message = "Bu e-posta ile kayıtlı hesap bulunamadı.";
          break;
        case 'failed-precondition':
          final raw = (e.message ?? "").toLowerCase();
          if (raw.contains("yeni sms için")) {
            message =
                "Kod zaten gönderildi. Tekrar göndermek için ${_formatSeconds(otpTimerReset.value)} bekleyin.";
          } else {
            message = e.message ?? "Bu hesap için kayıtlı telefon bulunamadı.";
          }
          break;
        case 'unavailable':
          message = "SMS servisine ulaşılamadı. Lütfen tekrar deneyin.";
          break;
        default:
          message = "Kod gönderilemedi. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Kod Gönderilemedi", message);
    } catch (_) {
      AppSnackbar("Kod Gönderilemedi", "SMS gönderilirken bir hata oluştu.");
    } finally {
      wait.value = false;
    }
  }

  void startOtpTimerForTimer() {
    _timerReset?.cancel(); // Var olan timer varsa iptal et
    otpTimerReset.value = 300;

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
    resetUserID.value = "";
    // 1. Önce email ile ara
    try {
      final emailUser = await _userRepository.findUserByEmail(
        email,
        preferCache: true,
      );

      if (emailUser != null) {
        resetPhoneNumber.value = (emailUser["phoneNumber"] ?? "").toString();
        resetUserID.value = (emailUser["id"] ?? "").toString();
        return;
      }

      // 2. Email bulunamadıysa nickname ile ara
      final nickUser = await _userRepository.findUserByNickname(
        nickname,
        preferCache: true,
      );

      if (nickUser != null) {
        resetPhoneNumber.value = (nickUser["phoneNumber"] ?? "").toString();
        resetUserID.value = (nickUser["id"] ?? "").toString();
      }
    } catch (_) {
      // Sign-in ekranında users read kuralı kapalıysa sessiz fallback.
    }
  }

  Future<void> sendPasswordResetLink() async {
    // Backward compatibility: eski çağrılar da SMS reset akışını kullansın.
    await sendOtpCodeForReset();
  }

  Future<void> verifyResetSmsCode() async {
    final targetEmail = resetMailController.text.trim().toLowerCase();
    final code = resetOtpController.text.trim();

    if (!isValidEmail(targetEmail)) {
      AppSnackbar("Geçersiz E-posta", "Lütfen geçerli bir e-posta girin.");
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      AppSnackbar("Geçersiz Kod", "Lütfen 6 haneli doğrulama kodunu girin.");
      return;
    }

    wait.value = true;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyPasswordResetSmsCode')
          .call({
        "email": targetEmail,
        "verificationCode": code,
      });
      selection.value = 6;
      resetOtpFocus.value.unfocus();
      resetMailFocus.value.unfocus();
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'deadline-exceeded':
          message = "Kodun süresi doldu (60 sn). Lütfen yeni kod isteyin.";
          break;
        case 'not-found':
          message = "Doğrulama kodu bulunamadı. Yeniden kod alın.";
          break;
        case 'invalid-argument':
          message = "Doğrulama kodu hatalı.";
          break;
        case 'failed-precondition':
          message = e.message ?? "Kod artık geçerli değil. Yeni kod alın.";
          break;
        default:
          message = "Kod doğrulanamadı. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Doğrulama Başarısız", message);
    } catch (_) {
      AppSnackbar(
        "Doğrulama Başarısız",
        "Kod doğrulanırken bir hata oluştu.",
      );
    } finally {
      wait.value = false;
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
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      await _restoreAccountIfPendingDeletion();
      await MandatoryFollowService.instance.enforceForCurrentUser();

      // 2. Giriş başarılıysa, şifreyi güncelle
      await userCredential.user!.updatePassword(newPassword);
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      print("Şifre Firebase Auth üzerinde güncellendi.");

      // 🔥 CRITICAL: Re-initialize CurrentUserService after password reset login
      print("🔄 CurrentUserService yeniden başlatılıyor...");
      await CurrentUserService.instance.initialize();
      await NotificationService.instance.initialize();
      await _clearSessionCachesAfterAccountSwitch();
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

        await agendaController.refreshAgenda();

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

      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      _ensureFeedTabSelected();
      Get.offAll(() => const SplashView());
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

  Future<bool> signIn() async {
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
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      print("Giriş başarılı! Kullanıcı UID: ${userCredential.user?.uid}");
      await _restoreAccountIfPendingDeletion();
      await CurrentUserService.instance.refreshEmailVerificationStatus(
        reloadAuthUser: true,
      );
      // Login akışını kilitlememek için ağır işlemleri arka plana al.
      unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
      unawaited(_postLoginWarmup());

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
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      _ensureFeedTabSelected();
      Get.offAll(() => NavBarView());
      return true;
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
      return false;
    } catch (e) {
      print("Beklenmeyen bir hata oluştu: $e");
      wait.value = false;
      if (authSucceeded || FirebaseAuth.instance.currentUser != null) {
        // Giriş tamamlandıysa, sonraki hazırlık hataları kullanıcıyı login ekranında tutmasın.
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        _ensureFeedTabSelected();
        Get.offAll(() => NavBarView());
        return true;
      }
      AppSnackbar("Giriş Başarısız",
          "Giriş sırasında beklenmeyen bir hata oluştu. Lütfen tekrar deneyin. (-2)");
      return false;
    }
  }

  Future<void> _postLoginWarmup() async {
    try {
      print("🔄 Post-login warmup başladı...");
      await Future.any([
        CurrentUserService.instance.initialize(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      unawaited(NotificationService.instance.initialize());
      unawaited(_clearSessionCachesAfterAccountSwitch());
      unawaited(CurrentUserService.instance.forceRefresh());

      try {
        final storyController = Get.find<StoryRowController>();
        await Future.any([
          storyController.loadStories(limit: 100, cacheFirst: false),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (e) {
        print("⚠️ Post-login story warmup hatası: $e");
      }

      try {
        final agendaController = Get.isRegistered<AgendaController>()
            ? Get.find<AgendaController>()
            : Get.put(AgendaController());
        await Future.any([
          agendaController.refreshAgenda(),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (agendaController.agendaList.isEmpty) {
          unawaited(agendaController.fetchAgendaBigData(initial: true));
        }
      } catch (e) {
        print("⚠️ Post-login agenda warmup hatası: $e");
      }
    } catch (e) {
      print("⚠️ Post-login warmup genel hata: $e");
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

      final found = await _userRepository.findFirstByNicknamePrefix(
        search,
        preferCache: true,
      );

      if (found != null) {
        final nickname = (found["nickname"] ?? "").toString();
        final email = (found["email"] ?? "").toString();
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
