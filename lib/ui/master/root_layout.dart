import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:van_rec/router.dart' as router;

import 'adaptive_navigation.dart';

/// A root layout widget that adapts its display based on the target platform.
class RootLayout extends StatelessWidget {
  const RootLayout({
    super.key,
    required this.child,
  });

  final Widget child;
  static const _switcherKey = ValueKey('switcherKey');
  static const _navigationRailKey = ValueKey('navigationRailKey');

  /// Calculate the selected index for navigation based on the current location.
  static int? _calculateSelectedIndex(BuildContext context) {
    final destinations = router.destinations;
    if (destinations == null || destinations.isEmpty) {
      return null;
    }
    final location = GoRouterState.of(context).uri.toString();

    for (var i = 0; i < destinations.length; i++) {
      final route = destinations[i].route;
      if (route == "/") {
        if (location == route) return i;
        continue;
      }
      if (location.startsWith(route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;

    final currentIndex = _calculateSelectedIndex(context);
    final destination = router.destinations ?? [];

    final adaptiveChild = AdaptiveNavigation(
      key: _navigationRailKey,
      destinations: destination
          .map((e) => NavigationDestination(
                icon: e.icon,
                label: e.label,
              ))
          .toList(),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        context.go(destination[index].route);
      },
      child: child,
    );
    // Display as AdaptiveNavigation for desktop, or animate the switch for other platforms.
    return isDesktop
        ? adaptiveChild
        : AnimatedSwitcher(
            key: _switcherKey,
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: adaptiveChild,
          );
  }
}
