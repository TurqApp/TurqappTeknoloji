import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';

class MarketCategorySheet extends StatelessWidget {
  const MarketCategorySheet({
    super.key,
    required this.controller,
  });

  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.categories;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(120),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Text(
              'Kategoriler',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _tile(
                      label: 'Tum Kategoriler',
                      selected: controller.selectedCategoryKey.value.isEmpty,
                      onTap: () {
                        controller.selectCategory('');
                        Navigator.of(context).pop();
                      },
                    );
                  }
                  final item = categories[index - 1];
                  final key = (item['key'] ?? '').toString();
                  final label = (item['label'] ?? '').toString();
                  return _tile(
                    label: label,
                    selected: controller.selectedCategoryKey.value == key,
                    onTap: () {
                      controller.selectCategory(key);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
