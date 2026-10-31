import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'screens/create_edit.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';
import 'services/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled locally in assets/google_fonts/.
  GoogleFonts.config.allowRuntimeFetching = false;
  await AppSettingsController.instance.load();
  runApp(const HabitMasteryApp());
}

class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettingsController.instance,
      builder: (context, _) {
        final settings = AppSettingsController.instance.settings;
        return MaterialApp(
          title: 'Habit Mastery App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: Colors.green,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              primary: Colors.green.shade800,
              secondary: Colors.greenAccent,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
              primary: Colors.greenAccent,
              secondary: Colors.lightGreenAccent,
            ),
            scaffoldBackgroundColor: const Color(0xFF17231B),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF263D2E),
              foregroundColor: Colors.white,
            ),
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return TickerMode(
              enabled: !settings.reducedMotion,
              child: MediaQuery(
                data: media.copyWith(disableAnimations: settings.reducedMotion),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: PersistentTabView(
            tabs: [
              PersistentTabConfig(
                screen: const Dashboard(),
                item: ItemConfig(
                  icon: const Icon(Icons.home),
                  title: 'Dashboard',
                  iconSize: 32,
                  activeForegroundColor: settings.darkMode
                      ? Colors.white
                      : Colors.black,
                  inactiveForegroundColor: settings.darkMode
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
              PersistentTabConfig(
                screen: const CreateEdit(),
                item: ItemConfig(
                  icon: const Icon(Icons.add_circle_outline),
                  title: 'Plant Habit',
                  iconSize: 32,
                  activeForegroundColor: settings.darkMode
                      ? Colors.white
                      : Colors.black,
                  inactiveForegroundColor: settings.darkMode
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
              PersistentTabConfig(
                screen: const History(),
                item: ItemConfig(
                  icon: const Icon(Icons.history),
                  title: 'History',
                  iconSize: 32,
                  activeForegroundColor: settings.darkMode
                      ? Colors.white
                      : Colors.black,
                  inactiveForegroundColor: settings.darkMode
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ],
            navBarBuilder: (navBarConfig) => Style1BottomNavBar(
              navBarConfig: navBarConfig,
              height: 65,
              navBarDecoration: NavBarDecoration(
                color: settings.darkMode
                    ? const Color(0xFF263D2E)
                    : Colors.greenAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
