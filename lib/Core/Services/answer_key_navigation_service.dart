import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormEntry/optical_form_entry.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart';

class AnswerKeyNavigationService {
  const AnswerKeyNavigationService();

  Future<void> openSearchAnswerKey() async {
    await Get.to(() => const SearchAnswerKey());
  }

  Future<void> openCategoryAnswerKey(String sinavTuru) async {
    await Get.to(() => CategoryBasedAnswerKey(sinavTuru: sinavTuru));
  }

  Future<void> openPublishedAnswerKeys() async {
    await Get.to(() => const OpticsAndBooksPublished());
  }

  Future<void> openSavedOpticalForms() async {
    await Get.to(() => const SavedOpticalForms());
  }

  Future<void> openMyBookletResults() async {
    await Get.to(() => const MyBookletResults());
  }

  Future<void> openCreateAnswerKey({required Function onBack}) async {
    await Get.to(() => AnswerKeyCreatingOption(onBack: onBack));
  }

  Future<void> openOpticalFormEntry() async {
    await Get.to(() => const OpticalFormEntry());
  }

  Future<void> openBookletAnswer({
    required AnswerKeySubModel model,
    required BookletModel anaModel,
  }) async {
    await Get.to(() => BookletAnswer(model: model, anaModel: anaModel));
  }

  Future<void> openBookletPreview(BookletModel model) async {
    await Get.to(() => BookletPreview(model: model));
  }
}
