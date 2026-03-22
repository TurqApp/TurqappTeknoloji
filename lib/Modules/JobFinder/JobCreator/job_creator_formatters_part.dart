part of 'job_creator.dart';

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;

    if (clipped.length >= 2) {
      final hour = int.tryParse(clipped.substring(0, 2)) ?? -1;
      if (hour < 0 || hour > 23) {
        return oldValue;
      }
    }

    if (clipped.length >= 3) {
      final minuteTens = int.tryParse(clipped.substring(2, 3)) ?? -1;
      if (minuteTens < 0 || minuteTens > 5) {
        return oldValue;
      }
    }

    if (clipped.length == 4) {
      final minute = int.tryParse(clipped.substring(2, 4)) ?? -1;
      if (minute < 0 || minute > 59) {
        return oldValue;
      }
    }

    final formatted = clipped.length <= 2
        ? clipped
        : '${clipped.substring(0, 2)}:${clipped.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThousandsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final reversed = digits.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    final formatted = chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
