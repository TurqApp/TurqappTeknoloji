part of 'sign_in_controller.dart';

final UserRepository _userRepository = UserRepository.ensure();
final UserSubdocRepository _userSubdocRepository = ensureUserSubdocRepository();
final SignInApplicationService _signInApplicationService =
    SignInApplicationService();
const DeviceSessionRuntimeService _deviceSessionRuntimeService =
    DeviceSessionRuntimeService();
SignInRemoteService get _remoteService => SignInRemoteService.ensure();
const String _loginWord = 'TurqApp';

void _logSignupOtp(String stage, [Map<String, Object?> details = const {}]) {
  debugPrint('[SignupOtp] $stage ${details.isEmpty ? "" : details}');
}

void _ensureFeedTabSelected() {
  const PrimaryTabRouter().openFeed();
}

String _formatSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final m = (safe ~/ 60).toString().padLeft(2, '0');
  final s = (safe % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

extension SignInControllerWarmEntryPart on SignInController {
  void onAuthEntryScreenVisible() {
    final currentSelection = selection.value;
    debugPrint(
      '[AuthEntryWarm] status=screen_visible selection=$currentSelection',
    );
    Future<void>.microtask(() async {
      debugPrint(
        '[AuthEntryWarm] status=queued selection=$currentSelection',
      );
      if (currentSelection == 1) {
        final context = Get.context;
        if (authEntryIsFirstLaunch && context != null) {
          unawaited(SignInEntryWarmService.ensureSliderAssetPrecaching(context));
        }
        unawaited(
          SignInEntryWarmService.ensurePasajStarted(
            source: 'sign_in_screen_selection_${currentSelection}_fastlane',
            isFirstLaunch: authEntryIsFirstLaunch,
          ),
        );
      }
      await SignInEntryWarmService.ensureStarted(
        source: 'sign_in_screen_selection_$currentSelection',
        isFirstLaunch: authEntryIsFirstLaunch,
      );
    });
  }
}
