// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsPart on _SettingsViewState {
  void _ensureDiagnosticsServices() {
    ErrorHandlingService.ensure();
    NetworkAwarenessService.ensure();
    UploadQueueService.ensure();
    DraftService.ensure();
    PostEditingService.ensure();
    MediaEnhancementService.ensure();
    OfflineModeService.ensure();
  }
}
