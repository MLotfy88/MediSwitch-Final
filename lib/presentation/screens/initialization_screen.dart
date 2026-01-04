import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added

import '../../core/database/database_helper.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/services/unified_sync_service.dart'; // Added
import '../../data/datasources/local/sqlite_local_data_source.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../presentation/bloc/subscription_provider.dart';
import 'main_screen.dart';

// Keys from main.dart
// Onboarding key removed as it's no longer used

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  bool _hasError = false;
  String _errorMessage = "";

  // Showcase State
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  Map<String, int> _dbStats = {};

  final List<Map<String, String>> _insights = [
    {
      "title": "Clinical Intelligence",
      "subtitle":
          "MediSwitch identifies over 15,000 disease-drug contraindications instantly powered by DDInter 2.0.",
    },
    {
      "title": "Interaction Matrix",
      "subtitle":
          "Our engine analyzes 140,000+ interaction rules in milliseconds to maximize patient safety.",
    },
    {
      "title": "Dietary Awareness",
      "subtitle":
          "From grapefruit juice to caffeine, we alert you to critical food-drug interactions as they happen.",
    },
    {
      "title": "Advanced Management",
      "subtitle":
          "Get evidence-based clinical management text and safe alternatives for high-risk prescriptions.",
    },
    {
      "title": "Pediatric Precision",
      "subtitle":
          "Access specific dosage guidelines for children ensured by reliable clinical sources.",
    },
  ];

  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _logger.i("InitializationScreen: initState called.");
    _startAutoSlide();
    _determineInitialRoute();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_currentPage < _insights.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    // Smoother progress bar animation over 5 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        if (_loadingProgress < 1.0) {
          _loadingProgress += 0.01; // 50ms * 100 = 5000ms
        } else {
          _progressTimer?.cancel();
        }
      });
    });
  }

  Future<void> _determineInitialRoute() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final startTime = DateTime.now();
        final bool success = await _performFullInitialization();

        if (success && mounted) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          const minDelay =
              5500; // Slightly more than 5s to allow progress bar to finish
          if (elapsed < minDelay) {
            await Future.delayed(Duration(milliseconds: minDelay - elapsed));
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        }
      } catch (e, s) {
        _logger.e("InitializationScreen: Fatal Error", e, s);
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = "App launch error: $e";
          });
        }
      }
    });
  }

  // Placeholder for background tasks if needed
  void _backgroundPrime() {
    Future.microtask(() async {
      try {
        await _performFullInitialization(isBackground: true);
      } catch (e) {
        _logger.e("InitializationScreen: Background priming failed", e);
      }
    });
  }

  Future<bool> _performFullInitialization({bool isBackground = false}) async {
    try {
      await locator.isReady<DatabaseHelper>();
      final localDataSource = locator<SqliteLocalDataSource>();

      // 1. Consolidated Initialization
      await localDataSource.ensureDatabaseInitialized();

      // Load stats for the footer
      final stats = await localDataSource.getDashboardStatistics();
      if (mounted) {
        setState(() {
          _dbStats = stats;
        });
      }

      // 2. Initialize Provider & Interactions
      locator<SubscriptionProvider>().initialize();

      // Force reload interaction data to ensure it's not stale after seeding
      final interactionRepo = locator<InteractionRepository>();
      await interactionRepo.loadInteractionData();

      // 3. Quick Notification Sync (Added for background update)
      try {
        final syncService = locator<UnifiedSyncService>();
        final prefs = await SharedPreferences.getInstance();
        // Fire and forget - don't block UI for this
        syncService.syncNotifications(prefs).ignore();
      } catch (e) {
        _logger.w("InitializationScreen: Notification sync warning: $e");
      }

      return true;
    } catch (e, s) {
      _logger.e("InitializationScreen: Initialization error", e, s);
      if (!isBackground) {
        _updateError("Error loading data: $e");
      }
      return false;
    }
  }

  void _updateError(String msg) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  "Sorry, an error occurred during launch",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => _determineInitialRoute(),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              const Spacer(flex: 2),
              // Logo placeholder or existing logo widget if available
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Color(0xFF1EB980),
                      ),
                ),
              ),
              const SizedBox(height: 40),

              // Carousel
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _insights.length,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final insight = _insights[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Text(
                            insight['title']!,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF1EB980),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            insight['subtitle']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1EB980),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Stats Footer
              if (_dbStats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "${_dbStats['total_medicines']} Drugs | ${_dbStats['total_interactions']} Interactions | ${_dbStats['active_ingredients']} Ingredients",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Text(
                  "Updating database rules...",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const Spacer(flex: 3),
            ],
          ),

          // Page indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _insights.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  width: _currentPage == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? const Color(0xFF1EB980)
                            : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
