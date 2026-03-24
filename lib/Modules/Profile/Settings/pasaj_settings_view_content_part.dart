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

  List<String> _resolvedPasajTabs() {
    final tabs = controller.pasajOrder.toList(growable: true);
    if (!tabs.contains(PasajTabIds.practiceExams)) {
      final onlineIndex = tabs.indexOf(PasajTabIds.onlineExam);
      if (onlineIndex >= 0) {
        tabs.insert(onlineIndex, PasajTabIds.practiceExams);
      } else {
        tabs.add(PasajTabIds.practiceExams);
      }
    }
    return tabs;
  }
}
