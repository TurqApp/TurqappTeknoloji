import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';

class MarketShareService {
  const MarketShareService();

  String buildPublicUrl(String itemId) {
    return 'https://turqapp.com/market/$itemId';
  }

  String buildInternalUrl(String itemId) {
    return 'turqapp://market/$itemId';
  }

  Future<void> shareItem(MarketItemModel item) async {
    final price = '${item.price.toStringAsFixed(0)} ${item.currency}';
    final text = <String>[
      item.title.trim(),
      price,
      if (item.locationText.trim().isNotEmpty) item.locationText.trim(),
      buildPublicUrl(item.id),
    ].where((line) => line.isNotEmpty).join('\n');

    await ShareActionGuard.run(() {
      return ShareLinkService.shareUrl(
        url: text,
        title: item.title,
        subject: item.title,
      );
    });
  }
}
