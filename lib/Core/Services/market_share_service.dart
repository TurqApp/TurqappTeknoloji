import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';

class MarketShareService {
  const MarketShareService();

  String buildPublicUrl(String itemId) {
    return 'https://turqapp.com/m/$itemId';
  }

  String buildInternalUrl(String itemId) {
    return 'turqapp://market/$itemId';
  }

  Future<void> shareItem(MarketItemModel item) async {
    final shortUrl = ShortLinkService().getMarketPublicUrlForImmediateShare(
      itemId: item.id,
      title: item.title,
      desc: item.description,
      imageUrl: item.coverImageUrl.isNotEmpty
          ? item.coverImageUrl
          : (item.imageUrls.isNotEmpty ? item.imageUrls.first : ''),
    );

    final url = shortUrl.trim().isNotEmpty ? shortUrl : buildPublicUrl(item.id);

    await ShareActionGuard.run(() {
      return ShareLinkService.shareUrl(
        url: url,
        title: item.title,
        subject: item.title,
      );
    });
  }
}
