import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

class SignInRemoteService extends GetxService {
  static const String _signupAvailabilityUrl =
      'https://europe-west3-turqappteknoloji.cloudfunctions.net/checkSignupAvailabilityHttp';

  static SignInRemoteService? maybeFind() {
    final isRegistered = Get.isRegistered<SignInRemoteService>();
    if (!isRegistered) return null;
    return Get.find<SignInRemoteService>();
  }

  static SignInRemoteService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SignInRemoteService(), permanent: true);
  }

  final FirebaseFunctions _functions =
      AppCloudFunctions.instanceFor(region: 'europe-west3');
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  Future<void> sendPasswordResetSmsCode({required String email}) async {
    await _functions.httpsCallable('sendPasswordResetSmsCode').call({
      'email': normalizeEmailAddress(email),
    });
  }

  Future<void> verifyPasswordResetSmsCode({
    required String email,
    required String verificationCode,
  }) async {
    await _functions.httpsCallable('verifyPasswordResetSmsCode').call({
      'email': normalizeEmailAddress(email),
      'verificationCode': verificationCode.trim(),
    });
  }

  Future<({bool emailAvailable, bool nicknameAvailable, bool reachable})>
      checkSignupAvailability({
    String? email,
    String? nickname,
  }) async {
    final normalizedEmail = normalizeEmailAddress(email);
    final normalizedNickname = normalizeNicknameInput(nickname ?? '');
    try {
      final response = await _dio.post(
        _signupAvailabilityUrl,
        data: {
          if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
          if (normalizedNickname.isNotEmpty) 'nickname': normalizedNickname,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return (
        emailAvailable: _asBool(data['emailAvailable']),
        nicknameAvailable: _asBool(data['nicknameAvailable']),
        reachable: true,
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        return (
          emailAvailable: _asBool(responseData['emailAvailable']),
          nicknameAvailable: _asBool(responseData['nicknameAvailable']),
          reachable: error.response?.statusCode == 400,
        );
      }
      return (
        emailAvailable: false,
        nicknameAvailable: false,
        reachable: false,
      );
    }
  }

  Future<void> sendSignupSmsCode({
    required String phone,
    required String email,
    required String nickname,
  }) async {
    await _functions.httpsCallable('sendSignupSmsCode').call({
      'phone': phone.trim(),
      'email': normalizeEmailAddress(email),
      'nickname': normalizeNicknameInput(nickname),
    });
  }

  Future<void> verifySignupSmsCode({
    required String phone,
    required String verificationCode,
    required String email,
    required String nickname,
  }) async {
    await _functions.httpsCallable('verifySignupSmsCode').call({
      'phone': phone.trim(),
      'verificationCode': verificationCode.trim(),
      'email': normalizeEmailAddress(email),
      'nickname': normalizeNicknameInput(nickname),
    });
  }
}
