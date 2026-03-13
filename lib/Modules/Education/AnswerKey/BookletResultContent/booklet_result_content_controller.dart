import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';

class BookletResultContentController extends GetxController {
  final BookletResultModel model;
  final anaModel = Rx<BookletModel?>(null);
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  BookletResultContentController(this.model) {
    getData();
  }

  Future<void> getData() async {
    anaModel.value = await _bookletRepository.fetchById(model.kitapcikID);
  }
}
