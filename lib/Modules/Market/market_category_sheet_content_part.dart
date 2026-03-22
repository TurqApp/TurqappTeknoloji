part of 'market_category_sheet.dart';

extension _MarketCategorySheetContentPart on _MarketCategorySheetState {
  Widget _buildPage(BuildContext context) {
    if (widget.topLevelOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          openTopLevelOnlyPicker().then((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(title: 'pasaj.market.categories'.tr),
            const SizedBox(height: 12),
            _selectorTile(
              label:
                  _selectedTopLabel ?? 'pasaj.market.create.main_category'.tr,
              onTap: _openTopCategorySheet,
            ),
            const SizedBox(height: 8),
            for (var level = 0; level < _categoryLevels.length; level++)
              if (_shouldShowLevel(level)) ...[
                _selectorTile(
                  label: _selectedNodes.length > level
                      ? _selectedNodes[level].label
                      : _levelLabel(level),
                  onTap: () => _openCategoryLevelSheet(level),
                ),
                const SizedBox(height: 8),
              ],
            if (_selectedPathText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPathText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.controller.selectCategory('');
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color(0x22000000)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'pasaj.market.all_categories'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCategoryKey.isEmpty
                        ? null
                        : () {
                            widget.controller
                                .selectCategory(_selectedCategoryKey);
                            Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'pasaj.market.filter.apply'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? get _selectedTopLabel {
    if (_selectedTopKey.isEmpty) return null;
    for (final item in _topCategories) {
      if ((item['key'] ?? '').toString() == _selectedTopKey) {
        return _categoryLabel(item);
      }
    }
    return null;
  }

  String get _selectedCategoryKey {
    if (_selectedNodes.isEmpty) return _selectedTopKey;
    return _selectedNodes.last.key;
  }

  String get _selectedPathText {
    if (_selectedNodes.isEmpty) return '';
    return _selectedNodes.last.pathLabels.skip(1).join(' > ');
  }

  Widget _selectorTile({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowLevel(int level) => _optionsForLevel(level).length > 1;

  String _levelLabel(int level) {
    switch (level) {
      case 0:
        return 'pasaj.market.create.subcategory'.tr;
      case 1:
        return 'pasaj.market.create.subgroup'.tr;
      case 2:
        return 'pasaj.market.create.product_type'.tr;
      default:
        return 'pasaj.market.create.level'.trParams({'value': '${level + 1}'});
    }
  }
}
