import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'screens/create_edit.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitMasteryApp());
}

class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: const Dashboard(),
            item: ItemConfig(
              icon: const Icon(Icons.home),
              title: 'Dashboard',
              iconSize: 32,
              activeForegroundColor: Colors.black,
              inactiveForegroundColor: Colors.black54,
            ),
          ),
          PersistentTabConfig(
            screen: const CreateEdit(),
            item: ItemConfig(
              icon: const Icon(Icons.add_circle_outline),
              title: 'Plant Habit',
              iconSize: 32,
              activeForegroundColor: Colors.black,
              inactiveForegroundColor: Colors.black54,
            ),
          ),
          PersistentTabConfig(
            screen: const History(),
            item: ItemConfig(
              icon: const Icon(Icons.history),
              title: 'History',
              iconSize: 32,
              activeForegroundColor: Colors.black,
              inactiveForegroundColor: Colors.black54,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          height: 65,
          navBarDecoration: const NavBarDecoration(
            color: Colors.greenAccent,
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
  }
}
