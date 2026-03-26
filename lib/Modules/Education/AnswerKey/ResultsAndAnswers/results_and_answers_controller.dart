import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'results_and_answers_controller_facade_part.dart';
part 'results_and_answers_controller_fields_part.dart';
part 'results_and_answers_controller_runtime_part.dart';

class ResultsAndAnswersController extends GetxController {
  final _state = _ResultsAndAnswersControllerState();
  final OpticalFormModel model;

  ResultsAndAnswersController(this.model);

  @override
  void onInit() {
    super.onInit();
    getCevaplarim();
  }

  Future<void> getCevaplarim() => _getResultsAndAnswers(this);

  void hesaplaDogruYanlisBos() => _calculateResultsAndAnswers(this);
}
