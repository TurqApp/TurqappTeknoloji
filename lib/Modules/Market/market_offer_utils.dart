const String kMarketOfferStatusPending = 'pending';
const String kMarketOfferStatusAccepted = 'accepted';
const String kMarketOfferStatusRejected = 'rejected';
const String kMarketOfferStatusCancelled = 'cancelled';

String marketCurrencyLabel(String currency) {
  final normalized = currency.trim().toUpperCase();
  if (normalized == 'TRY') return 'TL';
  return currency.trim();
}

String normalizeMarketOfferStatus(String status) {
  switch (status.trim()) {
    case kMarketOfferStatusAccepted:
      return kMarketOfferStatusAccepted;
    case kMarketOfferStatusRejected:
      return kMarketOfferStatusRejected;
    case kMarketOfferStatusCancelled:
      return kMarketOfferStatusCancelled;
    default:
      return kMarketOfferStatusPending;
  }
}
