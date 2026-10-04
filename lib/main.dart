import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'routes/app_routes.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const ESenyasApp());
}

/// Root widget for the e-Senyas application.
///
/// Wraps the MaterialApp with [ChangeNotifierProvider] for [AppProvider]
/// and configures theme, routes, and dark-mode switching.
class ESenyasApp extends StatelessWidget {
  const ESenyasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'e-Senyas',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appProvider.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.launch,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
