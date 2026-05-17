import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color systemNavigationSurfaceColor = Colors.black;
const Color tabBarNavigationSurfaceColor = Color(0xD9FFFFFF);
const Color filteredSystemNavigationSurfaceColor = Colors.black;

final ValueNotifier<bool> useFilteredSystemNavigationSurface =
    ValueNotifier<bool>(true);

SystemUiOverlayStyle systemOverlayStyleForNavigationSurface(bool filtered) {
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: filtered ? Brightness.light : Brightness.dark,
    statusBarBrightness: filtered ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarDividerColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
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
