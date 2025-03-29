import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../bloc/dose_calculator_provider.dart'; // Import the new provider
import 'home_screen.dart';
import 'dose_comparison_screen.dart';
import 'weight_calculator_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the current tab

  // List of the screens wrapped with necessary providers
  // Note: HomeScreen already gets MedicineProvider higher up in main.dart
  // We only need to provide DoseCalculatorProvider here for DoseComparisonScreen
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // Assumes MedicineProvider is provided above this widget tree
    ChangeNotifierProvider(
      // Provide DoseCalculatorProvider for this screen
      create: (_) => DoseCalculatorProvider(),
      child: const DoseComparisonScreen(), // Use the renamed screen
    ),
    const WeightCalculatorScreen(), // Assuming this doesn't need a specific provider yet
    const SettingsScreen(), // Assuming this doesn't need a specific provider yet
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep the state of the screens when switching tabs
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      // body: Center(child: _widgetOptions.elementAt(_selectedIndex)), // Old way - loses state
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_outlined),
            activeIcon: Icon(Icons.compare_arrows),
            label: 'مقارنة الجرعات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'حاسبة الوزن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            Theme.of(context).primaryColor, // Or your desired color
        unselectedItemColor: Colors.grey, // Color for inactive tabs
        showUnselectedLabels: true, // Show labels for inactive tabs
        onTap: _onItemTapped,
        type:
            BottomNavigationBarType
                .fixed, // Ensures all items are visible and have labels
      ),
    );
  }
}
