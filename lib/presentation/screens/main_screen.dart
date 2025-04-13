import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'home_screen.dart'; // Keep import for later
import 'settings_screen.dart'; // Re-enable SettingsScreen import
import '../widgets/custom_nav_bar.dart'; // Re-enable CustomNavBar import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 3; // Start with Settings tab selected for testing

  // Keep HomeScreen as placeholder, use actual SettingsScreen
  final List<Widget> _screens = [
    const Center(child: Text('Home Placeholder')), // Placeholder for HomeScreen
    const Center(child: Text('Alternatives Tab Placeholder')),
    const Center(
      child: Text('حاسبة الجرعات (قريباً)'),
    ), // Placeholder for Calculator
    const SettingsScreen(), // Use actual SettingsScreen
  ];

  // Map keys should ideally be unique identifiers for the screens
  // final Map<int, String> _navigatorKeys = {
  //   0: 'HomeScreen',
  //   1: 'AlternativesPlaceholder',
  //   2: 'WeightCalculatorPlaceholder',
  //   3: 'SettingsScreen',
  // };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use IndexedStack to show the selected screen
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      // Re-enable BottomNavigationBar
      bottomNavigationBar: CustomNavBar(
        // Use the custom navigation bar
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: const [
          NavBarItem(icon: Icons.home_outlined, label: 'الرئيسية'),
          NavBarItem(
            icon: Icons.swap_horiz_outlined,
            label: 'البدائل',
          ), // Placeholder icon/label
          NavBarItem(icon: Icons.calculate_outlined, label: 'الحاسبة'),
          NavBarItem(icon: Icons.settings_outlined, label: 'الإعدادات'),
        ],
      ),
    );
  }
}
