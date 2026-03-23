part of 'account_center_view.dart';

Future<String?> _loadPersonalContactDetails({
  required CurrentUserService currentUserService,
  required UserRepository userRepository,
}) async {
  final current = currentUserService.currentUser;
  final parts = <String>[];

  final directEmail = (current?.email ?? currentUserService.email).trim();
  final directPhone =
      (current?.phoneNumber ?? currentUserService.phoneNumber).trim();
  if (directEmail.isNotEmpty) parts.add(directEmail);
  if (directPhone.isNotEmpty) parts.add(directPhone);
  if (parts.isNotEmpty) return parts.join(', ');

  return _loadFallbackPersonalContactDetails(
    currentUserService: currentUserService,
    userRepository: userRepository,
  );
}
