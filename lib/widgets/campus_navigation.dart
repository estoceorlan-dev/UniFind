import 'campus_scaffold.dart';
import 'package:flutter/material.dart';

class CampusNavigation extends StatelessWidget {
  const CampusNavigation({
    super.key,
    required this.index,
    required this.onSelect,
    required this.messages,
    required this.alerts,
    this.pending,
  });
  final int index, messages, alerts;
  final int? pending;
  final ValueChanged<int> onSelect;

  NavigationDestination destination(
    String label,
    IconData icon,
    IconData selected, [
    int count = 0,
  ]) {
    Widget symbol(IconData data) =>
        Badge.count(count: count, isLabelVisible: count > 0, child: Icon(data));
    return NavigationDestination(
      label: label,
      icon: symbol(icon),
      selectedIcon: symbol(selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      destination('Feed', Icons.dashboard_outlined, Icons.dashboard_rounded),
      destination(
        'Chats',
        Icons.chat_bubble_outline,
        Icons.chat_bubble_rounded,
        messages,
      ),
      destination(
        'Alerts',
        Icons.notifications_none,
        Icons.notifications_rounded,
        alerts,
      ),
      destination(
        'Items',
        Icons.inventory_2_outlined,
        Icons.inventory_2_rounded,
      ),
      if (pending != null)
        destination(
          'Users',
          Icons.people_outline,
          Icons.people_rounded,
          pending!,
        ),
    ];
    final size = MediaQuery.sizeOf(context);
    if (usesCampusRail(size)) {
      final extended = size.width >= 1100;
      return NavigationRail(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        extended: extended,
        scrollable: true,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        destinations: [
          for (final item in destinations)
            NavigationRailDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: Text(item.label),
            ),
        ],
      );
    }
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      destinations: destinations,
      height: size.height < 480 ? 60 : null,
      labelBehavior:
          size.width < 310 || MediaQuery.textScalerOf(context).scale(12) > 20
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}

Route<void> campusTabRoute(BuildContext context, Widget page) =>
    PageRouteBuilder<void>(
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
