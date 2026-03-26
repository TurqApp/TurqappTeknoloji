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
