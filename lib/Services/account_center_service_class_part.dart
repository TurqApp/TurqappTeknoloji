part of 'account_center_service.dart';

class AccountCenterService extends GetxService {
  final _state = _AccountCenterServiceState();

  @override
  void onInit() {
    super.onInit();
    _handleAccountCenterServiceInit(this);
  }
}
