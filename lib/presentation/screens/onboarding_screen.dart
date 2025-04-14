import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import 'main_screen.dart'; // Import MainScreen to navigate to

const String _prefsKeyOnboardingDone = 'onboarding_complete';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Get logger instance
  // Note: Accessing locator directly in StatelessWidget is generally okay if it's already initialized.
  static final FileLoggerService _logger = locator<FileLoggerService>();

  // Function called when Done or Skip button is pressed
  void _onIntroEnd(BuildContext context) async {
    _logger.i("OnboardingScreen: _onIntroEnd called.");
    // Mark onboarding as complete in SharedPreferences
    try {
      final prefs = await locator.getAsync<SharedPreferences>();
      await prefs.setBool(_prefsKeyOnboardingDone, true);
      _logger.i("OnboardingScreen: Onboarding marked as complete.");
    } catch (e, s) {
      // Correct logger call: message, error, stackTrace
      _logger.e("OnboardingScreen: Error saving onboarding status.", e, s);
    }

    // Navigate to the MainScreen and replace the onboarding screen
    if (context.mounted) {
      _logger.i("OnboardingScreen: Navigating to MainScreen.");
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      _logger.w(
        "OnboardingScreen: Context not mounted after _onIntroEnd async gap.",
      );
    }
  }

  // Helper to build page decoration
  PageDecoration _buildPageDecoration(BuildContext context) {
    return PageDecoration(
      titleTextStyle: Theme.of(
        context,
      ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
      bodyTextStyle: Theme.of(context).textTheme.bodyLarge!,
      bodyPadding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
      imagePadding: const EdgeInsets.all(24.0),
      pageColor: Theme.of(context).colorScheme.background,
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("OnboardingScreen: Building widget.");
    final pageDecoration = _buildPageDecoration(context);

    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(), // Unique key
      globalBackgroundColor: Theme.of(context).colorScheme.background,

      // Define the pages
      pages: [
        PageViewModel(
          title: "مرحباً بك في MediSwitch",
          body:
              "دليلك الشامل للأدوية في مصر. ابحث بسهولة عن الأدوية، بدائلها، وجرعاتها.",
          image: const Center(
            child: Icon(Icons.medication_liquid_outlined, size: 150.0),
          ), // Placeholder image
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "بحث سريع وذكي",
          body:
              "ابحث بالاسم التجاري أو المادة الفعالة واحصل على النتائج فوراً. استخدم الفلاتر لتضييق نطاق البحث.",
          image: const Center(
            child: Icon(Icons.search_outlined, size: 150.0),
          ), // Placeholder image
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "حاسبة الجرعات والبدائل",
          body:
              "احسب الجرعات بدقة بناءً على الوزن والعمر، واكتشف البدائل المتاحة بسهولة.",
          image: const Center(
            child: Icon(Icons.calculate_outlined, size: 150.0),
          ), // Placeholder image
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "مدقق التفاعلات الدوائية",
          body:
              "تأكد من أمان استخدام الأدوية معاً عن طريق فحص التفاعلات المحتملة بينها.",
          image: const Center(
            child: Icon(Icons.health_and_safety_outlined, size: 150.0),
          ), // Placeholder image
          decoration: pageDecoration,
        ),
      ],

      // --- Navigation Buttons ---
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // Allow skipping
      showSkipButton: true,
      skip: Text(
        'تخطي',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      next: const Icon(Icons.arrow_forward),
      done: Text(
        'ابدأ الآن',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),

      // --- Dots Indicator ---
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        color: Theme.of(context).colorScheme.outline.withOpacity(
          0.3,
        ), // Use theme color for inactive dots
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),

      // --- Other Options ---
      // curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      isProgress: true,
      isProgressTap: true,
      // freeze: false, // Allow scrolling back
    );
  }
}
