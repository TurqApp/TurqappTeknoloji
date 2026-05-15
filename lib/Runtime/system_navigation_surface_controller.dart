import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color systemNavigationSurfaceColor = Color(0xE6FFFFFF);
const Color tabBarNavigationSurfaceColor = Color(0xD9FFFFFF);
const Color filteredSystemNavigationSurfaceColor = Color(0x66000000);

final ValueNotifier<bool> useFilteredSystemNavigationSurface =
    ValueNotifier<bool>(true);

SystemUiOverlayStyle systemOverlayStyleForNavigationSurface(bool filtered) {
  final navigationColor =
      filtered ? Colors.black : systemNavigationSurfaceColor;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: filtered ? Brightness.light : Brightness.dark,
    statusBarBrightness: filtered ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: navigationColor,
    systemNavigationBarDividerColor: navigationColor,
    systemNavigationBarIconBrightness:
        filtered ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

void setFilteredSystemNavigationSurface(bool filtered) {
  if (useFilteredSystemNavigationSurface.value != filtered) {
    useFilteredSystemNavigationSurface.value = filtered;
  }
  SystemChrome.setSystemUIOverlayStyle(
    systemOverlayStyleForNavigationSurface(filtered),
  );
}
