part of 'account_center_view.dart';

Future<String?> _loadPersonalContactDetails({
  required CurrentUserService currentUserService,
  required UserRepository userRepository,
}) async {
  final directContactDetails =
      _loadDirectPersonalContactDetails(currentUserService);
  if (directContactDetails != null) return directContactDetails;

  return _loadFallbackPersonalContactDetails(
    currentUserService: currentUserService,
    userRepository: userRepository,
  );
}
