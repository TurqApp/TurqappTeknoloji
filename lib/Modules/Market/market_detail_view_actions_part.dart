part of 'market_detail_view.dart';

extension _MarketDetailViewActionsPart on _MarketDetailViewState {
  Future<void> _performShowReportSheet() async {
    if (_isSubmittingReport) return;
    final selections =
        await _MarketDetailViewState._reportRepository.fetchSelections();
    final selected = await showCupertinoModalPopup<ReportModel>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text('pasaj.market.report_listing'.tr),
        message: Text('pasaj.market.report_reason'.tr),
        actions: selections
            .map(
              (selection) => CupertinoActionSheetAction(
                onPressed: () => Navigator.of(sheetContext).pop(selection),
                child: Text(selection.title),
              ),
            )
            .toList(growable: false),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          isDefaultAction: true,
          child: Text('common.cancel'.tr),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _submitReport(selected);
  }

  Future<void> _performSubmitReport(ReportModel selection) async {
    if (_isSubmittingReport) return;
    _updateViewState(() {
      _isSubmittingReport = true;
    });
    try {
      await _MarketDetailViewState._reportRepository.submitReport(
        targetUserId: item.userId,
        postId: item.id,
        commentId: '',
        selection: selection,
        targetType: 'market',
      );
      if (!mounted) return;
      AppSnackbar(
        'pasaj.market.report_received_title'.tr,
        'pasaj.market.report_received_body'.tr,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('common.error'.tr, 'pasaj.market.report_failed'.tr);
    } finally {
      _updateViewState(() {
        _isSubmittingReport = false;
      });
    }
  }

  Future<void> _performShowOfferSheet(BuildContext context) async {
    final double basePrice = item.price <= 0 ? 0.0 : item.price;
    final suggestionRates = <double>[0.70, 0.80, 0.90];
    final List<double> suggestions = suggestionRates
        .map((rate) => _normalizeOfferPrice(basePrice * rate))
        .where((value) => value > 0)
        .toSet()
        .toList();
    double? selectedOffer =
        suggestions.length > 1 ? suggestions[1] : suggestions.firstOrNull;
    bool customMode = false;
    final customController = TextEditingController(
      text: selectedOffer == null ? '' : _plainOfferText(selectedOffer),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submitOffer() async {
              final rawText = customController.text.trim().replaceAll('.', '');
              final offerPrice = customMode
                  ? double.tryParse(rawText.replaceAll(',', '.'))
                  : selectedOffer;
              if (offerPrice == null || offerPrice <= 0) {
                AppSnackbar(
                  'support.empty_title'.tr,
                  'pasaj.market.invalid_offer'.tr,
                );
                return;
              }
              try {
                await MarketOfferService.createOffer(
                  item: item,
                  offerPrice: offerPrice,
                  message: '',
                );
                _updateViewState(() {
                  _item = item.copyWith(offerCount: item.offerCount + 1);
                });
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                AppSnackbar('common.success'.tr, 'pasaj.market.offer_sent'.tr);
              } catch (e) {
                final message =
                    e.toString().contains('own_item_offer_not_allowed')
                        ? 'pasaj.market.offer_own_forbidden'.tr
                        : e.toString().contains('daily_offer_limit_reached')
                            ? 'pasaj.market.offer_daily_limit'.tr
                            : 'pasaj.market.offer_failed'.tr;
                AppSnackbar('common.error'.tr, message);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'pasaj.market.offer_count'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formattedMoney(selectedOffer ?? basePrice)} ${_currencyLabel(item.currency)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: suggestions.map((offer) {
                      final selected = !customMode && selectedOffer == offer;
                      final discount = basePrice > 0
                          ? ((1 - (offer / basePrice)) * 100).round()
                          : 0;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: offer == suggestions.last ? 0 : 10,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                customMode = false;
                                selectedOffer = offer;
                                customController.text = _plainOfferText(offer);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: selected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.black
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_formattedMoney(offer)} ${_currencyLabel(item.currency)}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 17,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$discount% indirim',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black45,
                                      fontSize: 11,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  if (customMode) ...[
                    TextField(
                      controller: customController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          _inputDecoration('pasaj.market.offer_count'.tr),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: submitOffer,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'pasaj.market.offer_count'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        customMode = true;
                        if (selectedOffer != null &&
                            customController.text.trim().isEmpty) {
                          customController.text =
                              _plainOfferText(selectedOffer!);
                        }
                      });
                    },
                    child: Text(
                      'pasaj.market.offer_count'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performRefreshItem({required bool silent}) async {
    if (_isRefreshing) return;
    if (!silent && mounted) {
      _updateViewState(() {
        _isRefreshing = true;
      });
    } else {
      _isRefreshing = true;
    }
    try {
      final latest = await _MarketDetailViewState._repository.fetchById(
        item.id,
        preferCache: false,
        forceRefresh: true,
      );
      if (latest != null && mounted) {
        final preserved = _preserveProtectedFields(latest, _item);
        _updateViewState(() {
          _item = preserved;
        });
      }
    } finally {
      if (!mounted) {
        _isRefreshing = false;
      } else {
        _updateViewState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  MarketItemModel _performPreserveProtectedFields(
    MarketItemModel remote,
    MarketItemModel local,
  ) {
    final shouldKeepPhone = !remote.canShowPhone &&
        local.canShowPhone &&
        local.sellerPhoneNumber.trim().isNotEmpty;

    if (!shouldKeepPhone) return remote;

    return remote.copyWith(
      showPhone: true,
      contactPreference: 'phone',
      sellerPhoneNumber: local.sellerPhoneNumber,
    );
  }

  Future<void> _performIncrementViewCount() async {
    final currentUid = CurrentUserService.instance.effectiveUserId.trim();
    if (currentUid.isNotEmpty && currentUid == item.userId) return;
    try {
      await _MarketDetailViewState._repository.incrementViewCount(
        docId: item.id,
        userId: item.userId,
      );
      _updateViewState(() {
        _item = item.copyWith(viewCount: item.viewCount + 1);
      });
    } catch (_) {}
  }

  Future<void> _performOpenEdit() async {
    final result = await Get.to(() => MarketCreateView(initialItem: item));
    if (result == null) return;
    await _refreshItem();
  }
}
