part of 'pasaj_settings_view.dart';

extension PasajSettingsViewDataPart on _PasajSettingsViewState {
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
