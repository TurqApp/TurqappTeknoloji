part of 'pasaj_settings_view.dart';

extension PasajSettingsViewContentPart on _PasajSettingsViewState {
  Widget _buildPasajList() {
    return Obx(() {
      final tabs = _resolvedPasajTabs();
      return ListView(
        padding: const EdgeInsets.fromLTRB(15, 6, 15, 20),
        children: tabs
            .map(
              (title) => _PasajToggleTile(
                key: ValueKey('pasaj-tile-$title'),
                controller: controller,
                title: title,
              ),
            )
            .toList(growable: false),
      );
    });
  }
}
