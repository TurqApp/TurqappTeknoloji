part of 'deneme_sinavi_preview_controller_library.dart';

extension DenemeSinaviPreviewControllerBasePart
    on DenemeSinaviPreviewController {
  static final Expando<_DenemeSinaviPreviewControllerState> _stateExpando =
      Expando<_DenemeSinaviPreviewControllerState>(
    'deneme_sinavi_preview_state',
  );

  _DenemeSinaviPreviewControllerState get _state =>
      _stateExpando[this] ??= _DenemeSinaviPreviewControllerState();
}

class DenemeSinaviPreviewController extends GetxController {
  final SinavModel model;
  DenemeSinaviPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviPreviewInit(this);
  }
}
