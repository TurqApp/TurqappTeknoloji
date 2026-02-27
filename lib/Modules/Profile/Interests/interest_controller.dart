import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/interests_list.dart';

class InterestsController extends GetxController {
  final RxList<String> selecteds = <String>[].obs;
  final RxString searchText = "".obs;
  final RxBool isReady = false.obs;
  static const int minSelection = 3;
  static const int maxSelection = 15;
  bool _userInteracted = false;
  bool _selectionLimitShown = false;

  String _norm(String value) {
    final lower = value.trim().toLowerCase();
    return lower
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _canonicalize(String value) {
    final n = _norm(value);
    for (final item in interestList) {
      if (_norm(item) == n) {
        return item;
      }
    }
    return value.trim();
  }

  String canonicalize(String value) => _canonicalize(value);

  bool isSelected(String item) {
    final canonical = _canonicalize(item);
    return selecteds.any((e) => _canonicalize(e) == canonical);
  }

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      final raw = doc.data()?["ilgialanlari"];
      if (!_userInteracted && raw is List) {
        selecteds.value = raw.map((e) => _canonicalize(e.toString())).toList();
      }
      isReady.value = true;
    }).catchError((_) {
      isReady.value = true;
    });
  }

  void select(String selection) {
    _userInteracted = true;
    final canonical = _canonicalize(selection);
    final idx = selecteds.indexWhere((e) => _norm(e) == _norm(canonical));
    if (idx >= 0) {
      selecteds.removeAt(idx);
    } else {
      if (selecteds.length >= maxSelection) {
        if (!_selectionLimitShown) {
          _selectionLimitShown = true;
          AppSnackbar(
            "Seçim Sınırı",
            "En fazla $maxSelection ilgi alanı seçebilirsiniz.",
          );
        }
        return;
      }
      selecteds.add(canonical);
    }
    selecteds.refresh();
  }

  List<String> filterItems(List<String> allItems) {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) {
      return allItems;
    }
    return allItems
        .where((item) => item.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> setData() async {
    if (selecteds.length < minSelection) {
      AppSnackbar(
        "Eksik Seçim",
        "En az $minSelection ilgi alanı seçmelisiniz.",
      );
      return;
    }

    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({"ilgialanlari": selecteds});

    Get.back();
  }
}
