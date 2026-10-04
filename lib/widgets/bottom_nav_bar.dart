import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Bottom navigation bar with 4 tabs matching the React prototype.
///
/// Tabs: Home, Isalin, Kasaysayan, Mga Setting.
/// Active tab shows a pill-shaped background indicator.
class ESenyasBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ESenyasBottomNavBar({super.key, required this.currentIndex});

  static const _items = [
    _NavItem(id: 'home', label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, route: '/menu'),
    _NavItem(id: 'translate', label: 'Isalin', icon: Icons.camera_alt_outlined, activeIcon: Icons.camera_alt, route: '/gesture-translation'),
    _NavItem(id: 'history', label: 'Kasaysayan', icon: Icons.history_outlined, activeIcon: Icons.history, route: '/history'),
    _NavItem(id: 'settings', label: 'Mga Setting', icon: Icons.settings_outlined, activeIcon: Icons.settings, route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;
    final borderColor = darkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final bgColor = darkMode ? ESenyasColors.cardDark : Colors.white;

    return Container(
      height: ESenyasDimens.bottomNavHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == currentIndex;
          return Expanded(
            child: _NavButton(
              item: item,
              active: active,
              darkMode: darkMode,
              onTap: () {
                if (i != currentIndex) {
                  Navigator.of(context).pushReplacementNamed(item.route);
                }
              },
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool darkMode;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.active,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = darkMode ? ESenyasColors.lightBlueText : ESenyasColors.primaryBlue;
    final inactiveColor = darkMode ? const Color(0xFFB0B0B0) : ESenyasColors.gray500;
    final pillColor = darkMode ? ESenyasColors.primaryBlueDark : ESenyasColors.surfaceBlueLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pill indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 28,
            decoration: BoxDecoration(
              color: active ? pillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active ? item.activeIcon : item.icon,
              size: 24,
              color: active ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? activeColor : inactiveColor,
              letterSpacing: active ? 0.01 : 0,
            ),
          ),
        ],
      ),
    );
  }
}
