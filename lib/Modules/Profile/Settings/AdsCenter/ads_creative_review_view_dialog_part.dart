part of 'ads_creative_review_view.dart';

extension AdsCreativeReviewViewDialogPart on AdsCreativeReviewView {
  Future<String?> _askNote(BuildContext context,
      {required String title}) async {
    final controller = TextEditingController();
    final output = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ads_center.review_note_hint'.tr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('common.save'.tr),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return output;
  }
}
