import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // No longer needed for local provider
import '../../core/di/locator.dart'; // Import locator
import '../../domain/services/analytics_service.dart'; // Import AnalyticsService
import 'home_screen.dart';
import 'alternatives_screen.dart'; // Import AlternativesScreen
import 'weight_calculator_screen.dart';
import 'settings_screen.dart';
import 'interaction_checker_screen.dart'; // Import Interaction Checker screen for potential future tab
import 'package:flutter_animate/flutter_animate.dart'; // Ensure flutter_animate is imported

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final AnalyticsService
  _analyticsService; // Declare AnalyticsService instance

  // List of the screens wrapped with necessary providers
  // Note: HomeScreen already gets MedicineProvider higher up in main.dart
  // List of the screens - Providers are now handled globally by locator + MultiProvider in main.dart
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    // AlternativesScreen needs an originalDrug. It cannot be a main tab directly.
    // Replace with a placeholder or remove this tab for now.
    const Center(child: Text('Alternatives Tab Placeholder')),
    // Temporarily disable WeightCalculatorScreen for MVP v1.0
    const Center(child: Text('حاسبة الجرعات (قريباً)')),
    // const WeightCalculatorScreen(),
    const SettingsScreen(),
    // const InteractionCheckerScreen(), // Example if added as a tab later
  ];

  // Map index to screen name for analytics
  final Map<int, String> _screenNames = {
    0: 'HomeScreen',
    1: 'AlternativesPlaceholder',
    2: 'WeightCalculatorPlaceholder', // Adjusted name
    3: 'SettingsScreen',
    // 4: 'InteractionCheckerScreen',
  };

  @override
  void initState() {
    super.initState();
    _analyticsService =
        locator<AnalyticsService>(); // Get instance from locator
    // Log initial screen view
    _logScreenView(0);
  }

  void _logScreenView(int index) {
    final screenName = _screenNames[index] ?? 'UnknownScreen';
    _analyticsService.logEvent(
      'screen_view',
      data: {'screen_name': screenName},
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Avoid logging if already selected
    setState(() {
      _selectedIndex = index;
    });
    _logScreenView(index); // Log screen view on tap
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AnimatedSwitcher for fade transition between screens
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // Match fade duration
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _widgetOptions.elementAt(_selectedIndex),
        // Important: Add a unique key to the child to ensure AnimatedSwitcher detects changes
        // key: ValueKey<int>(_selectedIndex), // This might reset state, test carefully
      ),
      // body: Center(child: _widgetOptions.elementAt(_selectedIndex)), // Old way - loses state
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined), // Changed icon
            activeIcon: Icon(Icons.alt_route), // Changed icon
            label: 'البدائل', // Changed label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'الحاسبة',
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
