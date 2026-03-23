part of 'market_saved_view.dart';

class _MarketSavedViewState extends State<MarketSavedView> {
  final MarketRepository _repository = MarketRepository.ensure();
  late final String uid;
  late Future<List<MarketItemModel>> _savedFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    uid = CurrentUserService.instance.effectiveUserId;
    _reload();
  }

  void _reload({bool force = false}) {
    _savedFuture = _repository.fetchSaved(
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
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <MarketItemModel>[];
          return RefreshIndicator(
            onRefresh: () async {
              _updateViewState(() => _reload(force: true));
            },
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
