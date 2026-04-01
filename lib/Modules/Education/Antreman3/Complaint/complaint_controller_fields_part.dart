part of 'complaint.dart';

class _ComplaintControllerState {
  final RxString selectedSikayet = ''.obs;
  final String userID = CurrentUserService.instance.effectiveUserId;
}

extension ComplaintControllerFieldsPart on ComplaintController {
  RxString get selectedSikayet => _state.selectedSikayet;
  String get userID => _state.userID;
}
