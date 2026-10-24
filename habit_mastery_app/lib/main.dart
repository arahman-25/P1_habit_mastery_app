import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'dashboard.dart';
import 'history.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitMasteryApp());
}

class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersistentTabView(  
        tabs: [
          PersistentTabConfig(
            screen: Dashboard(),
            item: ItemConfig(
              icon: Icon(Icons.home),
              title: 'Dashboard',
              iconSize: 35)
          ),
          PersistentTabConfig(
            screen: History(),
            item: ItemConfig(
              icon: Icon(Icons.history),
              title: 'History',
              iconSize: 35
              )
            )
        ], 
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          height: 70,
          navBarDecoration: NavBarDecoration(
            color: Colors.greenAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10  
              )
            ]
          ),))
    );
  }
}

