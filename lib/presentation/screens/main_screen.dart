import 'package:flutter/material.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'home_screen.dart';
import 'search_screen.dart'; // Import SearchScreen
import 'settings_screen.dart';
// Import placeholders for other screens for now
// import 'calculator_screen.dart';
// import 'interactions_screen.dart';
import '../widgets/custom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  int _selectedIndex = 0; // Start with Home tab selected

  // Update screens list to match the new BottomNavBar order
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(), // Use SearchScreen
    const Center(
      child: Text('حاسبة الجرعات (قريباً)'),
    ), // Placeholder for Calculator
    const Center(
      child: Text('التفاعلات (قريباً)'),
    ), // Placeholder for Interactions
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    _logger.i("MainScreen: _onItemTapped called with index: $index");
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("MainScreen: Building widget. Selected index: $_selectedIndex");
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: const [
          // Use LucideIcons and match design lab order/labels
          NavBarItem(icon: LucideIcons.home, label: 'الرئيسية'),
          NavBarItem(icon: LucideIcons.search, label: 'البحث'),
          NavBarItem(icon: LucideIcons.calculator, label: 'الحاسبة'),
          NavBarItem(
            icon: LucideIcons.zap,
            label: 'التفاعلات',
          ), // Zap icon for interactions
          NavBarItem(icon: LucideIcons.settings, label: 'الإعدادات'),
        ],
      ),
    );
  }
}
