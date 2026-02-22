import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';

class ActionButton extends StatelessWidget {
  final BuildContext context;
  final List<PullDownMenuItem> menuItems;

  const ActionButton({
    super.key,
    required this.context,
    required this.menuItems,
  });

  Future<bool> _canCreateScholarship() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final rozet = doc.get("rozet") as String? ?? "";
      return ["Kirmizi", "Sari", "Turkuaz"].contains(rozet);
    } catch (e) {
      AppSnackbar("Hata!", "Rozet kontrolü başarısız oldu.");
      print("Rozet kontrol hatası: $e");
      return false;
    }
  }

  Future<bool> _canCreateExam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final rozet = doc.get("rozet") as String? ?? "";
      return ["Turkuaz", "Sari"].contains(rozet);
    } catch (e) {
      AppSnackbar("Hata!", "Rozet kontrolü başarısız oldu.");
      print("Rozet kontrol hatası: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = false.obs;
    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) => isPressed.value = false,
      onTapCancel: () => isPressed.value = false,
      child: Obx(
        () => Opacity(
          opacity: isPressed.value ? 0.5 : 1.0,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            shape: CircleBorder(),
            onPressed: () {},
            child: FutureBuilder<Map<String, bool>>(
              future: Future.wait([
                _canCreateScholarship(),
                _canCreateExam(),
              ]).then(
                (results) => {
                  'canCreateScholarship': results[0],
                  'canCreateExam': results[1],
                },
              ),
              builder: (context, snapshot) {
                final canCreateScholarship =
                    snapshot.data?['canCreateScholarship'] ?? false;
                final canCreateExam = snapshot.data?['canCreateExam'] ?? false;
                return PullDownButton(
                  itemBuilder: (context) => menuItems
                      .map((item) {
                        if ((item.title == 'Burs Oluştur' ||
                                item.title == 'İlanlarım') &&
                            !canCreateScholarship) {
                          return null;
                        }
                        if (item.title == 'Deneme Oluştur' && !canCreateExam) {
                          return null;
                        }
                        return item;
                      })
                      .whereType<PullDownMenuItem>()
                      .toList(),
                  buttonBuilder: (context, showMenu) => IconButton(
                    icon: Icon(
                      Icons.grid_view_outlined,
                      color: Colors.white,
                      size: Theme.of(context).iconTheme.size ?? 25,
                    ),
                    onPressed: showMenu,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
