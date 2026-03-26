part of 'sign_in_controller.dart';

final UserRepository _userRepository = UserRepository.ensure();
final UserSubdocRepository _userSubdocRepository = ensureUserSubdocRepository();
final FirebaseFunctions _functions =
    FirebaseFunctions.instanceFor(region: 'europe-west3');
final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

const String _loginWord = 'TurqApp';
const String _signupAvailabilityUrl =
    'https://europe-west3-turqappteknoloji.cloudfunctions.net/checkSignupAvailabilityHttp';

void _logSignupOtp(String stage, [Map<String, Object?> details = const {}]) {
  debugPrint('[SignupOtp] $stage ${details.isEmpty ? "" : details}');
}

void _ensureFeedTabSelected() {
  final nav = NavBarController.maybeFind() ?? NavBarController.ensure();
  nav.selectedIndex.value = 0;
}

String _formatSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final m = (safe ~/ 60).toString().padLeft(2, '0');
  final s = (safe % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

Future<void> _clearSessionCachesAfterAccountSwitch() async {
  // User switch should preserve global content caches.
  // Warmup methods refresh user-scoped overlays and controllers afterward.
}
