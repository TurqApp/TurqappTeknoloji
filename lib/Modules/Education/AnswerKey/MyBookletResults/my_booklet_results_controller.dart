import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_booklet_results_controller_facade_part.dart';
part 'my_booklet_results_controller_fields_part.dart';
part 'my_booklet_results_controller_runtime_part.dart';

class MyBookletResultsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static MyBookletResultsController? maybeFind() =>
      maybeFindMyBookletResultsController();

  static MyBookletResultsController ensure({
    bool permanent = false,
  }) =>
      ensureMyBookletResultsController(permanent: permanent);

  final _state = _MyBookletResultsControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapResults());
  }
}
