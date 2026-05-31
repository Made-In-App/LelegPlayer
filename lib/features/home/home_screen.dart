import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTV = constraints.maxWidth > 1200;
      final isMobile = constraints.maxWidth < 600;

      if (isMobile) return _MobileScaffold(child: child);
      return _WideScaffold(child: child, isTV: isTV);
    });
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

const _navItems = [
  _NavItem('/', Icons.live_tv, 'Live TV'),
  _NavItem('/epg', Icons.grid_view, 'Guida TV'),
  _NavItem('/vod', Icons.movie, 'VOD'),
  _NavItem('/search', Icons.search, 'Cerca'),
  _NavItem('/playlists', Icons.playlist_add, 'Playlist'),
  _NavItem('/settings', Icons.settings, 'Impostazioni'),
];

// ── Mobile: bottom navigation bar ───────────────────────────

class _MobileScaffold extends StatelessWidget {
  final Widget child;
  const _MobileScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainItems = _navItems.take(4).toList();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceVariant,
        selectedIndex: mainItems.indexWhere((i) => i.path == location).clamp(0, 3),
        onDestinationSelected: (i) => context.go(mainItems[i].path),
        destinations: mainItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ── Tablet / TV / Desktop: navigation rail / drawer ─────────

class _WideScaffold extends StatelessWidget {
  final Widget child;
  final bool isTV;
  const _WideScaffold({required this.child, required this.isTV});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex =
        _navItems.indexWhere((i) => i.path == location).clamp(0, _navItems.length - 1);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isTV,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(_navItems[i].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isTV ? 'IPTV' : '▶',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            destinations: _navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
