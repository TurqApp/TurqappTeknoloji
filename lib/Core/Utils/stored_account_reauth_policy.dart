import 'package:turqappv2/Models/stored_account.dart';

bool requiresManualStoredAccountReauth(StoredAccount account) {
  return account.hasPasswordProvider;
}
