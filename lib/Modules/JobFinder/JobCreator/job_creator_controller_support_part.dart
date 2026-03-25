part of 'job_creator_controller.dart';

extension _JobCreatorControllerSupportX on JobCreatorController {
  String localizedWorkTypes(List<String> values) =>
      values.map(localizeJobWorkType).join(', ');

  String localizedWorkDays(List<String> values) =>
      values.map(localizeJobDay).join(', ');

  String localizedBenefits(List<String> values) =>
      values.map(localizeJobBenefit).join(', ');

  int parseMoneyInput(String value) {
    return int.tryParse(value.replaceAll('.', '').trim()) ?? 0;
  }

  String _formatMoneyInput(int value) {
    final raw = value.toString();
    final reversed = raw.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
  }

  void handleOnClose() {
    brand.dispose();
    about.dispose();
    isTanimi.dispose();
    maas1.dispose();
    maas2.dispose();
    calismaSaatiBaslangic.dispose();
    calismaSaatiBitis.dispose();
    basvuruSayisi.dispose();
    ilanBasligi.dispose();
    pozisyonSayisi.dispose();
    final currentLoader = GlobalLoaderController.maybeFind(tag: loaderTag);
    if (_ownsLoader && currentLoader != null) {
      Get.delete<GlobalLoaderController>(tag: loaderTag);
    }
  }
}
