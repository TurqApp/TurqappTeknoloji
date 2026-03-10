import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';

class BookletResultContentController extends GetxController {
  final BookletResultModel model;
  final anaModel = Rx<BookletModel?>(null);

  BookletResultContentController(this.model) {
    getData();
  }

  Future<void> getData() async {
    final doc = await FirebaseFirestore.instance
        .collection("books")
        .doc(model.kitapcikID)
        .get();

    anaModel.value = BookletModel.fromMap(doc.data() ?? {}, doc.id);
  }
}
