import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'home_screen.dart';
import 'search_screen.dart'; // Import SearchScreen
import 'settings_screen.dart';
// Import placeholders for other screens for now
// import 'calculator_screen.dart';
// import 'interactions_screen.dart';
import 'debug/log_viewer_screen.dart'; // Import the log viewer screen
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
  // Note: Placeholders should ideally be proper screens, but we localize the text for now.
  List<Widget> _getScreens(AppLocalizations l10n) => [
    const HomeScreen(),
    const SearchScreen(), // Use SearchScreen
    Center(
      child: Text(l10n.calculatorComingSoon), // Use localized string
    ), // Placeholder for Calculator
    Center(
      child: Text(l10n.interactionsComingSoon), // Use localized string
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
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    final screens = _getScreens(l10n); // Get screens with localized text
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ), // Use localized screens
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: [
          // Remove const
          // Use LucideIcons and match design lab order/labels
          NavBarItem(
            icon: LucideIcons.home,
            label: l10n.navHome,
          ), // Use localized string
          NavBarItem(
            icon: LucideIcons.search,
            label: l10n.navSearch,
          ), // Use localized string
          NavBarItem(
            icon: LucideIcons.calculator,
            label: l10n.navCalculator,
          ), // Use localized string
          NavBarItem(
            icon: LucideIcons.zap,
            label: l10n.navInteractions, // Use localized string
          ), // Zap icon for interactions
          NavBarItem(
            icon: LucideIcons.settings,
            label: l10n.navSettings,
          ), // Use localized string
        ],
      ),
      // Add FloatingActionButton only in debug mode
      floatingActionButton:
          kDebugMode
              ? FloatingActionButton(
                mini: true, // Make it smaller
                tooltip: l10n.viewLogsTooltip, // Use localized string
                onPressed: () {
                  _logger.i("Debug FAB tapped: Navigating to LogViewerScreen.");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogViewerScreen(),
                    ),
                  );
                },
                child: const Icon(LucideIcons.bug),
              )
              : null, // Don't show FAB in release mode
    );
  }
}
