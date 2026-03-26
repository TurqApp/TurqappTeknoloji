import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_stats_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_statistic_controller_fields_part.dart';
part 'my_statistic_controller_facade_part.dart';
part 'my_statistic_controller_runtime_part.dart';

class MyStatisticController extends GetxController {
  static MyStatisticController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureMyStatisticController(tag: tag, permanent: permanent);

  static MyStatisticController? maybeFind({String? tag}) =>
      _maybeFindMyStatisticController(tag: tag);
  final _MyStatisticControllerState _state = _MyStatisticControllerState();

  // Controls
  @override
  void onInit() {
    super.onInit();
    _handleMyStatisticControllerInit(this);
  }

  @override
  Future<void> refresh() async {
    await _loadAll();
  }

  @override
  void onClose() {
    _handleMyStatisticControllerClose(this);
    super.onClose();
  }

  void _handleOnInit() => _MyStatisticControllerRuntimeX(this).handleOnInit();

  void _handleOnClose() => _MyStatisticControllerRuntimeX(this).handleOnClose();

  Future<void> _loadAll() => _MyStatisticControllerRuntimeX(this).loadAll();
}
