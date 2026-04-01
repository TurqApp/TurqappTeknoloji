part of 'notify_reader_controller.dart';

const String _notifyReaderCommentType = kNotificationPostTypeCommentLower;
const Set<String> _notifyReaderProfileTypes = <String>{'follow', 'user'};
const Set<String> _notifyReaderTutoringTypes = <String>{
  'tutoring_application',
  'tutoring_status',
};
const Set<String> _notifyReaderChatTypes = <String>{'message', 'chat'};
const Set<String> _notifyReaderMarketTypes = <String>{
  'market_offer',
  'market_offer_status',
};

class _NotifyReaderControllerState {
  final NotifyLookupRepository lookupRepository =
      ensureNotifyLookupRepository();
  final RxString lastOpenedNotificationId = ''.obs;
  final RxString lastOpenedNotificationType = ''.obs;
  final RxString lastOpenedRouteKind = ''.obs;
  final RxString lastOpenedTargetId = ''.obs;
}

extension NotifyReaderControllerFieldsPart on NotifyReaderController {
  NotifyLookupRepository get _lookupRepository => _state.lookupRepository;
  RxString get lastOpenedNotificationId => _state.lastOpenedNotificationId;
  RxString get lastOpenedNotificationType => _state.lastOpenedNotificationType;
  RxString get lastOpenedRouteKind => _state.lastOpenedRouteKind;
  RxString get lastOpenedTargetId => _state.lastOpenedTargetId;
}
