import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../widgets/custom_nav_bar.dart';
import 'debug/log_viewer_screen.dart';
import 'favorites/favorites_screen.dart';
import 'history/history_screen.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'search_screen.dart'; // Import SearchScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  int _selectedIndex = 0; // Start with Home tab selected

  // Update screens list to match the new BottomNavBar order:
  // Home, Search, History, Favorites, Profile
  // Note: SearchScreen might be pushed or embedded. Reference app uses Tab navigation for these.
  // SearchScreen usually handles its own "Back" if pushed. But as a Tab, it should be the root of search.
  // Assuming SearchScreen accepts embedding or we wrap it.

  List<Widget> _getScreens() => [
    HomeScreen(
      onSearchTap: () => _onItemTapped(1), // Switch to Search tab (index 1)
    ),
    const SearchScreen(), // Ensure SearchScreen is stateful and handles being in a stack if needed
    const HistoryScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
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
    final l10n = AppLocalizations.of(context)!;
    final screens = _getScreens();

    return Scaffold(
      // Using IndexedStack for state preservation (Offline-first requirement)
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: [
          NavBarItem(icon: LucideIcons.home, label: l10n.navHome),
          NavBarItem(icon: LucideIcons.search, label: l10n.navSearch),
          NavBarItem(
            icon: LucideIcons.history, // Clock icon
            label: l10n.navHistory,
          ),
          NavBarItem(
            icon: LucideIcons.heart, // Heart icon
            label: l10n.navFavorites,
          ),
          NavBarItem(
            icon: LucideIcons.user, // User icon
            label: l10n.navProfile,
          ),
        ],
      ),
      // Add FloatingActionButton only in debug mode
      floatingActionButton:
          kDebugMode
              ? FloatingActionButton(
                mini: true,
                tooltip: l10n.viewLogsTooltip,
                onPressed: () {
                  _logger.i("Debug FAB tapped: Navigating to LogViewerScreen.");
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const LogViewerScreen(),
                    ),
                  );
                },
                child: const Icon(LucideIcons.bug),
              )
              : null,
    );
  }
}
