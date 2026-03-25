part of 'post_reshare_listing_controller.dart';

class _PostReshareListingControllerState {
  final reshareUsers = <ReshareUserItem>[].obs;
  final quoteUsers = <ReshareUserItem>[].obs;
  final isLoadingReshares = false.obs;
  final isLoadingQuotes = false.obs;
  final isLoadingMoreReshares = false.obs;
  final isLoadingMoreQuotes = false.obs;
  final hasMoreReshares = true.obs;
  final hasMoreQuotes = true.obs;
  final reshareScrollController = ScrollController();
  final quoteScrollController = ScrollController();
  DocumentSnapshot<Map<String, dynamic>>? lastReshareDoc;
  DocumentSnapshot<Map<String, dynamic>>? lastQuoteSharerDoc;
  bool fetchingReshares = false;
  bool fetchingQuotes = false;
  bool quotesInitialized = false;
}

extension PostReshareListingControllerFieldsPart
    on PostReshareListingController {
  RxList<ReshareUserItem> get reshareUsers => _state.reshareUsers;
  RxList<ReshareUserItem> get quoteUsers => _state.quoteUsers;
  RxBool get isLoadingReshares => _state.isLoadingReshares;
  RxBool get isLoadingQuotes => _state.isLoadingQuotes;
  RxBool get isLoadingMoreReshares => _state.isLoadingMoreReshares;
  RxBool get isLoadingMoreQuotes => _state.isLoadingMoreQuotes;
  RxBool get hasMoreReshares => _state.hasMoreReshares;
  RxBool get hasMoreQuotes => _state.hasMoreQuotes;
  ScrollController get reshareScrollController =>
      _state.reshareScrollController;
  ScrollController get quoteScrollController => _state.quoteScrollController;
  DocumentSnapshot<Map<String, dynamic>>? get _lastReshareDoc =>
      _state.lastReshareDoc;
  set _lastReshareDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastReshareDoc = value;
  DocumentSnapshot<Map<String, dynamic>>? get _lastQuoteSharerDoc =>
      _state.lastQuoteSharerDoc;
  set _lastQuoteSharerDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastQuoteSharerDoc = value;
  bool get _fetchingReshares => _state.fetchingReshares;
  set _fetchingReshares(bool value) => _state.fetchingReshares = value;
  bool get _fetchingQuotes => _state.fetchingQuotes;
  set _fetchingQuotes(bool value) => _state.fetchingQuotes = value;
  bool get _quotesInitialized => _state.quotesInitialized;
  set _quotesInitialized(bool value) => _state.quotesInitialized = value;
}
