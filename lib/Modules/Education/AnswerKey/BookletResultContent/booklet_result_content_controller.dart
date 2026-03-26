import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';

class BookletResultContentController extends GetxController {
  static BookletResultContentController ensure(
    BookletResultModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletResultContentController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletResultContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<BookletResultContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletResultContentController>(tag: tag);
  }

  final BookletResultModel model;
  final anaModel = Rx<BookletModel?>(null);
  final BookletRepository _bookletRepository = ensureBookletRepository();

  BookletResultContentController(this.model) {
    getData();
  }

  Future<void> getData() async {
    anaModel.value = await _bookletRepository.fetchById(model.kitapcikID);
  }
}
