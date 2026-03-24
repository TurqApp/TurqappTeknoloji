part of 'sign_in.dart';

extension SignInSignupPart on _SignInState {
  String _capitalizeWords(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
