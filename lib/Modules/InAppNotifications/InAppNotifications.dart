import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Modules/InAppNotifications/NotificationContent.dart';
import 'package:turqappv2/Modules/RecommendedUserList/RecommendedUserList.dart';
import 'package:turqappv2/Modules/RecommendedUserList/RecommendedUserListController.dart';

import 'InAppNotificationsController.dart';

class InAppNotifications extends StatelessWidget {
  InAppNotifications({super.key});
  final controller = Get.put(InAppNotificationsController());
  final recommendedController = Get.isRegistered<RecommendedUserListController>()
      ? Get.find<RecommendedUserListController>()
      : Get.put(RecommendedUserListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),

            // İçerik
            Expanded(
              child: Obx(() {
                if (!controller.complatedDataFetch.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(color: Colors.grey),
                  );
                }
                final children = <Widget>[
                  const SizedBox(height: 6),
                  const RecommendedUserList(batch: 1),
                  const SizedBox(height: 10),
                ];

                if (controller.list.isEmpty) {
                  children.add(EmptyRow(text: "Bildiriminiz"));
                } else {
                  final filtered = _filteredNotifications();
                  if (filtered.isEmpty) {
                    children.add(EmptyRow(text: "Bu filtrede bildirim yok"));
                  } else {
                    children.addAll(_buildGroupedList(filtered));
                  }
                }

                return ListView(
                  padding: EdgeInsets.zero,
                  children: children,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(CupertinoIcons.back, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              "Bildirimler",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontFamily: "MontserratBold",
                color: Colors.black,
              ),
            ),
          ),
          Obx(() {
            if (controller.list.isEmpty) {
              return const SizedBox(width: 48);
            }
            return PopupMenuButton<String>(
              onSelected: (v) {
                if (v == "clear_all") {
                  controller.list.clear();
                  controller.bildirimleriTopluSil();
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem<String>(
                  value: "clear_all",
                  child: Text("Tümünü Sil"),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  "Filtrele",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            _tabButton("Tümü", 0),
            const SizedBox(width: 10),
            _tabButton("Bahsedenler", 1),
          ],
        ),
      );
    });
  }

  Widget _tabButton(String text, int index) {
    final selected = controller.selection.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selection.value = index,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _filteredNotifications() {
    if (controller.selection.value == 0) return controller.list.toList();
    return controller.list
        .where(
          (n) =>
              n.desc.contains("@") ||
              n.postType == "Comment" ||
              n.desc.toLowerCase().contains("etiket"),
        )
        .toList();
  }

  List<Widget> _buildGroupedList(List<dynamic> notifications) {
    final widgets = <Widget>[];
    String? currentSection;

    for (var n in notifications) {
      final section = _sectionTitle((n.timeStamp is num ? n.timeStamp : 0).toInt());
      if (currentSection != section) {
        currentSection = section;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              section,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        );
      }

      widgets.add(
        Dismissible(
          key: ValueKey(n.docID),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => controller.delete(n.docID),
          child: NotificationContent(model: n),
        ),
      );
    }
    return widgets;
  }

  String _sectionTitle(int ts) {
    if (ts <= 0) return "Öne çıkanlar";
    final now = DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final startToday = DateTime(now.year, now.month, now.day);
    final startYesterday = startToday.subtract(const Duration(days: 1));

    if (d.isAfter(startToday)) return "Öne çıkanlar";
    if (d.isAfter(startYesterday)) return "Dün";
    return "Daha eski";
  }
}
