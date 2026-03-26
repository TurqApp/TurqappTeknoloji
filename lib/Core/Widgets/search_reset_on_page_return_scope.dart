import 'package:flutter/widgets.dart';

final SearchResetNavigatorObserver searchResetNavigatorObserver =
    SearchResetNavigatorObserver();

class SearchResetNavigatorObserver extends NavigatorObserver {
  final Map<Route<dynamic>, Set<VoidCallback>> _callbacksByRoute =
      <Route<dynamic>, Set<VoidCallback>>{};

  void register(Route<dynamic> route, VoidCallback callback) {
    final callbacks =
        _callbacksByRoute.putIfAbsent(route, () => <VoidCallback>{});
    callbacks.add(callback);
  }

  void unregister(Route<dynamic> route, VoidCallback callback) {
    final callbacks = _callbacksByRoute[route];
    if (callbacks == null) return;
    callbacks.remove(callback);
    if (callbacks.isEmpty) {
      _callbacksByRoute.remove(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is! PageRoute<dynamic> || previousRoute == null) return;
    final callbacks = _callbacksByRoute[previousRoute];
    if (callbacks == null || callbacks.isEmpty) return;
    for (final callback in callbacks.toList(growable: false)) {
      callback();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _callbacksByRoute.remove(route);
    super.didRemove(route, previousRoute);
  }
}

class SearchResetOnPageReturnScope extends StatefulWidget {
  const SearchResetOnPageReturnScope({
    super.key,
    required this.onReset,
    required this.child,
  });

  final VoidCallback onReset;
  final Widget child;

  @override
  State<SearchResetOnPageReturnScope> createState() =>
      _SearchResetOnPageReturnScopeState();
}

class _SearchResetOnPageReturnScopeState
    extends State<SearchResetOnPageReturnScope> {
  Route<dynamic>? _route;

  void _handlePageReturn() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onReset();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _route)) return;
    final previousRoute = _route;
    if (previousRoute != null) {
      searchResetNavigatorObserver.unregister(previousRoute, _handlePageReturn);
    }
    _route = route;
    searchResetNavigatorObserver.register(route, _handlePageReturn);
  }

  @override
  void dispose() {
    final route = _route;
    if (route != null) {
      searchResetNavigatorObserver.unregister(route, _handlePageReturn);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
