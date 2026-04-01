import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/jobs.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'job_selector_controller_facade_part.dart';
part 'job_selector_controller_fields_part.dart';

class JobSelectorController extends GetxController {
  final _state = _JobSelectorControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleJobSelectorInit(this);
  }
}
