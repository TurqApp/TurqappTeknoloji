enum RenderPatchOperationType {
  insert,
  remove,
  move,
  update,
  replace,
}

class RenderPatchOperation<T> {
  const RenderPatchOperation({
    required this.type,
    required this.index,
    this.fromIndex,
    this.item,
  });

  final RenderPatchOperationType type;
  final int index;
  final int? fromIndex;
  final T? item;
}

class RenderListPatch<T> {
  const RenderListPatch({
    required this.operations,
    this.reason = '',
  });

  final List<RenderPatchOperation<T>> operations;
  final String reason;

  bool get isEmpty => operations.isEmpty;

  static RenderListPatch<T> replaceAll<T>(
    List<T> items, {
    String reason = '',
  }) {
    return RenderListPatch<T>(
      reason: reason,
      operations: items
          .asMap()
          .entries
          .map(
            (entry) => RenderPatchOperation<T>(
              type: RenderPatchOperationType.replace,
              index: entry.key,
              item: entry.value,
            ),
          )
          .toList(growable: false),
    );
  }
}
