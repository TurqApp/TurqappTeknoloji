part of 'education_info_controller.dart';

extension _EducationInfoControllerLifecyclePart on EducationInfoController {
  void handleOnInit() {
    _initAnimationControllers();
    loadInitialData();
  }

  void handleOnClose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animationTurns.clear();
  }

  void _initAnimationControllers() {
    const labels = <String>[
      'Eğitim Seviyesi',
      'Ülke',
      'İl',
      'İlçe',
      'Okul',
      'Lise',
      'Üniversite',
      'Fakülte',
      'Bölüm',
      'Sınıf',
    ];
    for (final label in labels) {
      _animationControllers[label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _animationTurns[label] = 0.0.obs;
      _animationControllers[label]!.addListener(() {
        _animationTurns[label]!.value =
            _animationControllers[label]!.value * 0.5;
      });
    }
  }
}
