part of 'support_contact_view.dart';

extension SupportContactViewErrorPart on _SupportContactViewState {
  String _friendlyErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('not_authenticated')) {
      return 'support.error_not_authenticated'.tr;
    }
    if (raw.contains('empty_topic')) {
      return 'support.error_empty_topic'.tr;
    }
    if (raw.contains('empty_message')) {
      return 'support.empty_body'.tr;
    }
    return '${'support.error_body'.tr} $error';
  }
}
