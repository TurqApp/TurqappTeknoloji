part of 'market_view.dart';

extension _MarketViewStylePart on MarketView {
  Color _accentForItem(MarketItemModel item) {
    final lower = normalizeSearchText(item.categoryKey);
    if (lower.contains('elektronik') || lower.contains('telefon')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('ev-yasam') || lower.contains('mobilya')) {
      return const Color(0xFFEA580C);
    }
    if (lower.contains('spor')) {
      return const Color(0xFF16A34A);
    }
    return const Color(0xFF111827);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFB91C1C);
      case 'reserved':
        return const Color(0xFF2563EB);
      case 'draft':
        return const Color(0xFF7C3AED);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF111827);
    }
  }

  String _currencyLabel(String value) {
    return marketCurrencyLabel(value);
  }

  String _formattedPrice(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'pasaj.market.status.sold'.tr;
      case 'reserved':
        return 'pasaj.market.status.reserved'.tr;
      case 'draft':
        return 'pasaj.market.status.draft'.tr;
      case 'archived':
        return 'pasaj.market.status.archived'.tr;
      default:
        return 'pasaj.market.status.active'.tr;
    }
  }

  IconData _marketItemIcon(MarketItemModel item) {
    final lower = normalizeSearchText(
      '${item.categoryKey} ${item.categoryLabel}',
    );
    if (lower.contains('telefon') || lower.contains('iphone')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('bilgisayar') || lower.contains('laptop')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('koltuk') || lower.contains('mobilya')) {
      return Icons.chair_rounded;
    }
    if (lower.contains('ayakkabi')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.category_rounded;
  }

  Color _parseColor(String raw) {
    final normalized = raw.replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF111827;
    return Color(value);
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'add_circle':
        return Icons.add_circle;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'bookmark':
        return Icons.bookmark_border_rounded;
      case 'thumb_up':
        return Icons.bookmark_border_rounded;
      case 'local_offer':
        return Icons.local_offer_outlined;
      case 'apps':
        return Icons.apps_rounded;
      case 'near_me':
        return Icons.near_me_outlined;
      case 'devices':
        return Icons.devices_rounded;
      case 'phone':
      case 'phone_iphone':
        return Icons.phone_iphone_rounded;
      case 'computer':
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'joystick':
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'style':
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'weekend':
      case 'chair':
        return Icons.chair_rounded;
      case 'exercise':
      case 'sports_soccer':
        return Icons.sports_soccer_rounded;
      case 'child_friendly':
      case 'baby_changing_station':
        return Icons.child_friendly_rounded;
      case 'apartment':
      case 'home_work':
        return Icons.home_work_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'motorcycle':
        return Icons.two_wheeler_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'brush':
        return Icons.brush_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'toys':
        return Icons.toys_outlined;
      default:
        return Icons.category_rounded;
    }
  }

  IconData _categoryIconFor(Map<String, dynamic> category) {
    final label = normalizeSearchText((category['label'] ?? '').toString());
    final key = normalizeSearchText((category['key'] ?? '').toString());
    final lookup = '$label $key';

    if (lookup.contains('emlak')) return Icons.home_work_outlined;
    if (lookup.contains('telefon')) return Icons.phone_iphone_rounded;
    if (lookup.contains('elektronik')) return Icons.devices_rounded;
    if (lookup.contains('ev') || lookup.contains('yasam')) {
      return Icons.chair_rounded;
    }
    if (lookup.contains('motosiklet')) return Icons.two_wheeler_rounded;
    if (lookup.contains('giyim')) return Icons.checkroom_rounded;
    if (lookup.contains('kozmetik') || lookup.contains('kişisel')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lookup.contains('anne') || lookup.contains('bebek')) {
      return Icons.child_friendly_rounded;
    }
    if (lookup.contains('hobi')) return Icons.palette_outlined;
    if (lookup.contains('ofis')) return Icons.work_outline_rounded;
    if (lookup.contains('spor')) return Icons.sports_soccer_rounded;
    if (lookup.contains('kitap')) return Icons.menu_book_rounded;
    if (lookup.contains('oyuncak')) return Icons.toys_rounded;
    if (lookup.contains('pet')) return Icons.pets_rounded;
    if (lookup.contains('antika')) return Icons.auto_awesome_outlined;
    if (lookup.contains('yapi market')) return Icons.handyman_rounded;
    return _iconFor((category['icon'] ?? 'category').toString());
  }
}
