const String kMarketOfferStatusPending = 'pending';
const String kMarketOfferStatusAccepted = 'accepted';
const String kMarketOfferStatusRejected = 'rejected';
const String kMarketOfferStatusCancelled = 'cancelled';

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
