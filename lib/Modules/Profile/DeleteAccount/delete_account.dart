import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Core/app_snackbar.dart';
import '../../../Services/phone_account_limiter.dart';
import '../../SignIn/sign_in.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  static const int _deletionGraceDays = 30;
  final TextEditingController _codeController = TextEditingController();
  final int _color = 0xFF000000;

  String _phoneNumber = "";
  String _email = "";

  bool _isCodeSent = false;
  bool _isBusy = false;
  int _countdown = 0;
  Timer? _timer;
  final UserRepository _userRepository = UserRepository.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void initState() {
    super.initState();
    final current = CurrentUserService.instance.currentUser;
    _phoneNumber = (current?.phoneNumber ?? '').trim();
    _email = normalizeEmailAddress(current?.email);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: 'delete_account.title'.tr)],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'delete_account.confirm_title'.tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'delete_account.confirm_body'.tr,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontFamily: "Montserrat",
                          ),
                        ),
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _email,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Flexible(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'delete_account.code_hint'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "Montserrat",
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isBusy ? null : _sendDeleteCode,
                          child: Text(
                            _countdown > 0
                                ? "${_countdown}s"
                                : (_isCodeSent
                                    ? 'delete_account.resend'.tr
                                    : 'delete_account.send_code'.tr),
                            style: TextStyle(
                              color:
                                  _countdown > 0 ? Colors.grey : Color(_color),
                              fontSize: 14,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'delete_account.validity_notice'
                        .trParams({'days': '$_deletionGraceDays'}),
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontFamily: "Montserrat",
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isBusy ? null : _verifyAndDelete,
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isBusy
                            ? Colors.black.withValues(alpha: 0.35)
                            : Color(_color),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        _isBusy
                            ? 'delete_account.processing'.tr
                            : 'delete_account.delete_my_account'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDeleteCode() async {
    if (_countdown > 0 || _isBusy) return;
    if (_email.isEmpty) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.no_email_body'.tr,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.session_missing'.tr,
      );
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await user.getIdToken(true);
      await FirebaseFunctions.instanceFor(region: "europe-west3")
          .httpsCallable("sendEmailVerificationCode")
          .call({
        "email": _email,
        "purpose": "email_confirm",
        "idToken": await user.getIdToken(),
      });

      _startCountdown();
      if (!mounted) return;
      setState(() {
        _isCodeSent = true;
      });
      AppSnackbar(
        'delete_account.code_sent_title'.tr,
        'delete_account.code_sent_body'.tr,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        e.message ?? 'delete_account.send_failed'.tr,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('common.error'.tr, 'delete_account.send_failed'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _verifyAndDelete() async {
    if (_email.isEmpty) {
      await _requestDelete(context);
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 6) {
      AppSnackbar(
        'delete_account.invalid_code_title'.tr,
        'delete_account.invalid_code_body'.tr,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.session_missing'.tr,
      );
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await user.getIdToken(true);
      final idToken = await user.getIdToken();
      await FirebaseFunctions.instanceFor(region: "europe-west3")
          .httpsCallable("verifyEmailCode")
          .call({
        "email": _email,
        "purpose": "email_confirm",
        "verificationCode": code,
        "idToken": idToken,
      });

      await _requestDelete(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        e.message ?? 'delete_account.verify_failed'.tr,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('common.error'.tr, 'delete_account.verify_failed'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _requestDelete(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return;

    try {
      try {
        await PhoneAccountLimiter()
            .decrementOnUserDelete(uid: user.uid, phone: _phoneNumber);
      } catch (_) {}

      final now = DateTime.now();
      final scheduledAt = now.add(
        const Duration(days: _deletionGraceDays),
      );
      final userRef =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      await _userRepository.updateUserFields(
        user.uid,
        {
          "accountStatus": "pending_deletion",
          "isDeleted": true,
          "isPrivate": true,
          "deletionRequestedAt": DateTime.now().millisecondsSinceEpoch,
          "deletionScheduledAt": scheduledAt.millisecondsSinceEpoch,
          "updatedDate": DateTime.now().millisecondsSinceEpoch,
        },
        mergeIntoCache: false,
      );

      await userRef.collection("account_actions").add({
        "type": "deletion",
        "status": "pending",
        "reason": "self_service_request",
        "createdDate": DateTime.now().millisecondsSinceEpoch,
        "scheduledAt": scheduledAt.millisecondsSinceEpoch,
      });

      await _hideUserPosts(user.uid);

      await AccountCenterService.ensure().removeAccount(user.uid);
      await CurrentUserService.instance.logout();
      await auth.signOut();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            child: SignIn(),
          ),
        ),
      );

      AppSnackbar(
        'delete_account.request_received_title'.tr,
        'delete_account.request_received_body'
            .trParams({'days': '$_deletionGraceDays'}),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar(
        'common.error'.tr,
        'delete_account.request_failed'.tr,
      );
    }
  }

  Future<void> _hideUserPosts(String uid) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _postRepository.markAllPostsDeletedForUser(uid, nowMs: nowMs);
  }
}
