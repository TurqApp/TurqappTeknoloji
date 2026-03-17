import 'package:flutter/material.dart';

class PasajListingAdLayout {
  const PasajListingAdLayout._();

  static List<Widget> buildListChildren<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required Widget Function(int slot) adBuilder,
    int interval = 6,
  }) {
    final children = <Widget>[];
    var adSlot = 0;
    for (var index = 0; index < items.length; index++) {
      children.add(itemBuilder(items[index], index));
      if ((index + 1) % interval == 0) {
        children.add(adBuilder(adSlot++));
      }
    }
    return children;
  }

  static List<Widget> buildTwoColumnGridChildren<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required Widget Function(int slot) adBuilder,
    int interval = 6,
    double horizontalSpacing = 4,
    double rowSpacing = 4,
  }) {
    final children = <Widget>[];
    var adSlot = 0;

    for (var start = 0; start < items.length; start += 2) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: rowSpacing));
      }

      final first = itemBuilder(items[start], start);
      final secondIndex = start + 1;
      final second = secondIndex < items.length
          ? itemBuilder(items[secondIndex], secondIndex)
          : const SizedBox.shrink();

      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            SizedBox(width: horizontalSpacing),
            Expanded(child: second),
          ],
        ),
      );

      final processedCount = secondIndex < items.length ? secondIndex + 1 : start + 1;
      if (processedCount % interval == 0) {
        children.add(SizedBox(height: rowSpacing));
        children.add(adBuilder(adSlot++));
      }
    }

    return children;
  }
}
