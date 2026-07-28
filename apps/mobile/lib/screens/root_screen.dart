import 'package:flutter/material.dart';
import '../core/premium_theme.dart';
import '../core/premium_widgets.dart';
import '../core/responsive.dart';
import 'dashboard/dashboard_screen.dart';
import 'workouts/workouts_screen.dart';
import 'tools/tools_screen.dart';
import 'profile/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    WorkoutsScreen(),
    ToolsScreen(),
    ProfileScreen(),
  ];

  static const _destinations = [
    NavEntry(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'Dashboard'),
    NavEntry(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center, label: 'Workouts'),
    NavEntry(icon: Icons.calculate_outlined, selectedIcon: Icons.calculate, label: 'Tools'),
    NavEntry(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  void _onSelect(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    if (!context.isMediumWindow) return _CompactScaffold(index: _index, onSelect: _onSelect);

    return _SidebarScaffold(
      index: _index,
      onSelect: _onSelect,
      extended: context.isExpandedWindow,
    );
  }
}

/// Phone-width layout: full-bleed content with a floating glass pill nav
/// stacked on top (replicates `.navwrap` in the premium spec) instead of a
/// standard Material [NavigationBar] docked at the bottom.
class _CompactScaffold extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _CompactScaffold({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Premium.bg,
      body: Stack(
        children: [
          IndexedStack(index: index, children: _RootScreenState._screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: PillNavBar(
                index: index,
                onSelect: onSelect,
                entries: _RootScreenState._destinations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Persistent left-hand [NavigationRail] used once the window is wide enough
/// to behave like a laptop/desktop app (Windows desktop build, or a browser
/// tab sized like one) instead of a phone — collapsed (icons only) at medium
/// widths, extended with labels once there's room for a proper sidebar.
class _SidebarScaffold extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final bool extended;

  const _SidebarScaffold({required this.index, required this.onSelect, required this.extended});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Premium.bg,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onSelect,
            extended: extended,
            minExtendedWidth: 220,
            backgroundColor: Premium.surface,
            indicatorColor: Premium.accentDim,
            selectedIconTheme: const IconThemeData(color: Premium.accent),
            unselectedIconTheme: const IconThemeData(color: Premium.textFaint),
            selectedLabelTextStyle: Premium.body(13, weight: FontWeight.w600, color: Premium.text),
            unselectedLabelTextStyle: Premium.body(13, color: Premium.textDim),
            leading: Padding(
              padding: EdgeInsets.symmetric(vertical: extended ? 16 : 12),
              child: extended
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Premium.accent),
                          const SizedBox(width: 12),
                          Text('IronLog', style: Premium.heading(16)),
                        ],
                      ),
                    )
                  : const Icon(Icons.fitness_center, color: Premium.accent),
            ),
            destinations: _RootScreenState._destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Premium.border),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: extended ? 960 : double.infinity),
                child: IndexedStack(index: index, children: _RootScreenState._screens),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
