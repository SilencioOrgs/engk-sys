import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Custom app bar matching the React prototype's AppBar component.
///
/// 56 dp height, blue background, white text, optional back button.
class ESenyasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const ESenyasAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(ESenyasDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;
    final bgColor =
        darkMode ? ESenyasColors.primaryBlueDark : ESenyasColors.primaryBlue;

    return Container(
      height: ESenyasDimens.appBarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              splashRadius: 24,
              tooltip: 'Go back',
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: showBack ? 0 : 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}
