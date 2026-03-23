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

  final uid = currentUserService.effectiveUserId;
  if (uid.isEmpty) return null;
  final raw = await userRepository.getUserRaw(uid, preferCache: true);
  if (raw == null) return null;

  final fallbackParts = <String>[];
  final email = (raw['email'] ?? '').toString().trim();
  final phone = (raw['phoneNumber'] ?? '').toString().trim();
  if (email.isNotEmpty) fallbackParts.add(email);
  if (phone.isNotEmpty) fallbackParts.add(phone);
  if (fallbackParts.isEmpty) return null;
  return fallbackParts.join(', ');
}
