import 'package:flutter/material.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import 'home_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  int _selectedIndex = 0; // Start with Home tab selected

  // Use actual screens (except calculator placeholder)
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(
      child: Text('Alternatives Tab Placeholder'),
    ), // Keep placeholder for now
    const Center(
      child: Text('حاسبة الجرعات (قريباً)'),
    ), // Keep placeholder for MVP
    const SettingsScreen(),
  ];

  // Map keys should ideally be unique identifiers for the screens
  // final Map<int, String> _navigatorKeys = {
  //   0: 'HomeScreen',
  //   1: 'AlternativesPlaceholder',
  //   2: 'WeightCalculatorPlaceholder',
  //   3: 'SettingsScreen',
  // };

  void _onItemTapped(int index) {
    _logger.i("MainScreen: _onItemTapped called with index: $index");
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("MainScreen: Building widget. Selected index: $_selectedIndex");
    // Use IndexedStack to show the selected screen
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      // Re-enable BottomNavigationBar
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: const [
          NavBarItem(icon: Icons.home_outlined, label: 'الرئيسية'),
          NavBarItem(icon: Icons.swap_horiz_outlined, label: 'البدائل'),
          NavBarItem(icon: Icons.calculate_outlined, label: 'الحاسبة'),
          NavBarItem(icon: Icons.settings_outlined, label: 'الإعدادات'),
        ],
      ),
    );
  }
}
