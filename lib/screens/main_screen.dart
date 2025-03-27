import 'package:flutter/material.dart';
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

  // List of the screens to be displayed in the tabs
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    DoseComparisonScreen(),
    WeightCalculatorScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will display the widget from _widgetOptions based on the selected index
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
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
