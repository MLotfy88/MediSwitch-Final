import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'home_screen.dart';
// import 'weight_calculator_screen.dart';
// import 'settings_screen.dart';
// import '../widgets/custom_nav_bar.dart'; // Assuming this exists

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // int _selectedIndex = 0; // Keep track of the selected tab index

  // final List<Widget> _screens = [
  //   const HomeScreen(),
  //   // Replace with a placeholder or remove this tab for now.
  //   const Center(child: Text('Alternatives Tab Placeholder')),
  //   // Temporarily disable WeightCalculatorScreen for MVP v1.0
  //   const Center(child: Text('حاسبة الجرعات (قريباً)')),
  //   // const WeightCalculatorScreen(),
  //   const SettingsScreen(),
  // ];

  // // Map keys should ideally be unique identifiers for the screens
  // final Map<int, String> _navigatorKeys = {
  //   0: 'HomeScreen',
  //   1: 'AlternativesPlaceholder',
  //   2: 'WeightCalculatorPlaceholder', // Adjusted name
  //   3: 'SettingsScreen',
  // };

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Return a very simple Scaffold for testing
    return const Scaffold(body: Center(child: Text('MainScreen Placeholder')));

    // --- Original Scaffold with BottomNavBar commented out ---
    /*
    return Scaffold(
      body: IndexedStack( // Use IndexedStack to preserve state
        index: _selectedIndex,
        children: _screens.map((screen) {
          // You might need Navigator keys if you want separate navigation stacks per tab
          // For simplicity now, we just show the screen directly.
          return screen;
        }).toList(),
      ),
      bottomNavigationBar: CustomNavBar( // Use the custom navigation bar
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: const [
          NavBarItem(icon: Icons.home_outlined, label: 'الرئيسية'),
          NavBarItem(icon: Icons.swap_horiz_outlined, label: 'البدائل'), // Placeholder icon/label
          NavBarItem(icon: Icons.calculate_outlined, label: 'الحاسبة'),
          NavBarItem(icon: Icons.settings_outlined, label: 'الإعدادات'),
        ],
      ),
    );
    */
  }
}
