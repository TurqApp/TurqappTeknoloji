part of 'market_my_items_view.dart';

class _MarketMyItemsViewState extends State<MarketMyItemsView> {
  final MarketRepository _repository = MarketRepository.ensure();
  final MarketShareService _shareService = const MarketShareService();
  late final String uid;
  late Future<List<MarketItemModel>> _itemsFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    uid = CurrentUserService.instance.effectiveUserId;
    _reload();
  }

  void _reload({bool force = false}) {
    _itemsFuture = _repository.fetchByOwner(
      uid,
      preferCache: !force,
      forceRefresh: force,
    );
  }

  void _updateViewState(VoidCallback updates) {
    if (!mounted) return;
    setState(updates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.market.my_listings'.tr),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible = (snapshot.data ?? const <MarketItemModel>[])
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              _updateViewState(() => _reload(force: true));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
              children: [
                if (visible.isEmpty)
                  _buildEmptyState()
                else
                  ...visible.map(_buildItemCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          'pasaj.market.empty_my_listings'.tr,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }
}
