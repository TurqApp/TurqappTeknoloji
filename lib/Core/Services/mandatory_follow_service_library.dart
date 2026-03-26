class MandatoryFollowService {
  MandatoryFollowService._();
  static MandatoryFollowService? _instance;
  static MandatoryFollowService? maybeFind() => _instance;

  static MandatoryFollowService ensure() =>
      maybeFind() ?? (_instance = MandatoryFollowService._());

  static MandatoryFollowService get instance => ensure();

  Future<void> enforceForCurrentUser() async {
    // Zorunlu takip kapatildi. Uygulama acilisi veya oturum yenileme
    // sirasinda takip iliskisi otomatik kurulmaz.
    return;
  }
}
