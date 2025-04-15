import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'main_screen.dart'; // Import MainScreen for navigation

// Define the key here or move to a shared constants file
const String _prefsKeyOnboardingDone = 'onboarding_complete';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final FileLoggerService _logger = locator<FileLoggerService>();

  // Function to mark onboarding as complete and navigate
  void _onOnboardingComplete(BuildContext context) async {
    _logger.i(
      "OnboardingScreen: Onboarding complete. Navigating to MainScreen.",
    );
    final prefs = await locator.getAsync<SharedPreferences>();
    await prefs.setBool(_prefsKeyOnboardingDone, true);
    // Use pushReplacement to prevent going back to onboarding
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("OnboardingScreen: Building widget.");
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 19.0),
      imagePadding: EdgeInsets.only(
        top: 60,
        bottom: 24,
      ), // Adjust image padding
      pageColor: Colors.transparent, // Make page background transparent
      // Use theme colors if needed later
    );

    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(), // Add key
      globalBackgroundColor: colorScheme.background, // Use theme background
      allowImplicitScrolling: true, // Allow swiping between pages
      autoScrollDuration: null, // Disable auto-scroll

      pages: [
        PageViewModel(
          title: "مرحباً بك في MediSwitch",
          body:
              "دليلك الشامل للأدوية في مصر. ابحث بسهولة عن الأدوية، بدائلها، أسعارها، والمزيد.",
          image: _buildImage(LucideIcons.search), // Use Lucide icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "حاسبة الجرعات الذكية",
          body:
              "احسب الجرعات بدقة بناءً على وزن وعمر المريض لأدوية الأطفال الشائعة.",
          image: _buildImage(LucideIcons.calculator), // Use Lucide icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "مدقق التفاعلات الدوائية",
          body:
              "تجنب التفاعلات الخطيرة بين الأدوية عن طريق فحص قائمة الأدوية الخاصة بك.",
          image: _buildImage(LucideIcons.zap), // Use Lucide icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "البدائل والمواد الفعالة",
          body: "اعثر بسهولة على بدائل الأدوية المتاحة بنفس المادة الفعالة.",
          image: _buildImage(LucideIcons.replace), // Use Lucide icon
          decoration: pageDecoration,
        ),
      ],

      onDone: () => _onOnboardingComplete(context),
      onSkip:
          () => _onOnboardingComplete(context), // Skip goes to main screen too
      showSkipButton: true,
      skip: Text(
        'تخطي',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      next: Icon(LucideIcons.arrowRight, color: colorScheme.primary),
      done: Text(
        'تم',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),

      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: colorScheme.primary,
        color: colorScheme.outline.withOpacity(0.5),
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      // Customize button styles if needed
      // baseBtnStyle: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      // skipStyle: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      // doneStyle: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      // nextStyle: IconButton.styleFrom(foregroundColor: colorScheme.primary),
    );
  }

  // Helper to build image widget for pages
  Widget _buildImage(IconData icon, {double size = 150}) {
    return Center(
      child: Icon(
        icon,
        size: size,
        color: Colors.grey.shade400,
      ), // Use a muted color
    );
  }
}
