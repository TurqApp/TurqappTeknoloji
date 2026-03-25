part of 'optical_form_repository.dart';

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
