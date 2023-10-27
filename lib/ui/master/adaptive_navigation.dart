import 'package:flutter/material.dart';

/// A widget for adaptive navigation, which provides different layouts based on screen size.
class AdaptiveNavigation extends StatefulWidget {
  /// Creates an [AdaptiveNavigation] widget.
  ///
  /// - [destinations]: A list of navigation destinations.
  /// - [selectedIndex]: The index of the currently selected destination.
  /// - [onDestinationSelected]: A callback function for when a destination is selected.
  /// - [child]: The main content to display.
  const AdaptiveNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<NavigationDestination> destinations;
  final int? selectedIndex;
  final void Function(int index) onDestinationSelected;
  final Widget child;

  @override
  State<StatefulWidget> createState() => AdaptiveNavigationState();
}

/// The state class for [AdaptiveNavigation].
class AdaptiveNavigationState extends State<AdaptiveNavigation> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final query = MediaQuery.of(context);

        // Wide screen Layout
        if (constraints.maxWidth - query.padding.horizontal >= 600) {
          return _buildWideScreenLayout(context, constraints, query);
        }

        final showDrawer = widget.destinations.length > 4;

        // Mobile Layout
        return _buildMobileLayout(showDrawer);
      },
    );
  }

  // Builds the wide screen layout with a navigation rail.
  Widget _buildWideScreenLayout(
    BuildContext context,
    BoxConstraints constraints,
    MediaQueryData query,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: widget.destinations.isNotEmpty
            ? Row(
                children: [
                  NavigationRail(
                    extended:
                        constraints.maxWidth - query.padding.horizontal >= 800,
                    minExtendedWidth: 180,
                    destinations:
                        _buildNavigationRailDestinations(widget.destinations),
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                  ),
                  Expanded(child: ClipRect(child: widget.child)),
                ],
              )
            : widget.child,
      ),
    );
  }

  // Builds the mobile layout with a drawer or bottom navigation bar.
  Widget _buildMobileLayout(bool showDrawer) {
    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      drawer: showDrawer && widget.destinations.isNotEmpty
          ? _buildNavigationDrawer()
          : null,
      bottomNavigationBar: !showDrawer && widget.selectedIndex != null
          ? _buildNavigationBar()
          : null,
    );
  }

  // Builds the navigation drawer for the mobile layout.
  Widget _buildNavigationDrawer() {
    return Drawer(
      child: SafeArea(
        child: Expanded(child: _buildNavigationList()),
      ),
    );
  }

  // Builds the list of navigation items for the navigation drawer.
  Widget _buildNavigationList() {
    return ListView.separated(
      itemBuilder: (context, i) {
        final item = widget.destinations[i];
        return ListTile(
          leading: item.icon,
          title: Text(item.label),
          selected: i == widget.selectedIndex,
          onTap: () {
            _scaffoldKey.currentState!.closeDrawer();
            widget.onDestinationSelected(i);
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(),
      itemCount: widget.destinations.length,
    );
  }

  // Builds the bottom navigation bar for the mobile layout.
  Widget _buildNavigationBar() {
    return NavigationBar(
      destinations: widget.destinations,
      selectedIndex: widget.selectedIndex!,
      onDestinationSelected: widget.onDestinationSelected,
    );
  }

  // Builds the navigation rail destinations for the tablet layout.
  List<NavigationRailDestination> _buildNavigationRailDestinations(
      List<NavigationDestination> destinations) {
    return destinations
        .map((e) => NavigationRailDestination(
              icon: e.icon,
              label: Text(e.label),
            ))
        .toList();
  }
}
