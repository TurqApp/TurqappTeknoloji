part of 'market_saved_view.dart';

class _MarketSavedViewState extends State<MarketSavedView> {
  final MarketRepository _repository = ensureMarketRepository();
  late Future<List<MarketItemModel>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload({bool force = false}) {
    _savedFuture = _loadSavedItems(force: force);
  }

  Future<String> _resolveCurrentUid() async {
    final ensured = await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
      timeout: const Duration(seconds: 8),
    );
    return (ensured ?? CurrentUserService.instance.authUserId).trim();
  }

  Future<List<MarketItemModel>> _loadSavedItems({required bool force}) async {
    final uid = await _resolveCurrentUid();
    if (uid.isEmpty) return const <MarketItemModel>[];
    return _repository.fetchSaved(
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
        title: AppPageTitle('pasaj.market.saved_items'.tr),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _savedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppStateView.loading();
          }
          final items = snapshot.data ?? const <MarketItemModel>[];
          return RefreshIndicator(
            onRefresh: () async {
              _updateViewState(() => _reload(force: true));
            },
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildItemCard(items[index]),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Center(
          child: Text(
            'pasaj.market.saved_empty'.tr,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ],
    );
  }
}
