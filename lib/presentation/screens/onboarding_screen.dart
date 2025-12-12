import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'initialization_screen.dart'; // Import InitializationScreen

// Define the key here or move to a shared constants file
const String _prefsKeyOnboardingDone = 'onboarding_complete';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final FileLoggerService _logger = locator<FileLoggerService>();

  // Function to mark onboarding as complete and navigate appropriately
  // Function to mark onboarding as complete and navigate back to InitializationScreen
  void _onOnboardingComplete(BuildContext context) async {
    _logger.i("OnboardingScreen: Onboarding complete.");
    final prefs = await locator.getAsync<SharedPreferences>();

    // Mark onboarding as done
    await prefs.setBool(_prefsKeyOnboardingDone, true);
    _logger.i("OnboardingScreen: Set onboarding complete flag.");

    // Navigate back to InitializationScreen to re-evaluate route
    _logger.i("OnboardingScreen: Navigating back to InitializationScreen.");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InitializationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("OnboardingScreen: Building widget.");
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detect locale
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    // Define page decoration once
    final pageDecoration = PageDecoration(
      titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.bold,
      ), // Larger title
      bodyTextStyle: theme.textTheme.bodyLarge!, // Larger body text
      imagePadding: const EdgeInsets.only(
        top: 80,
        bottom: 24,
      ), // Adjust image padding
      pageColor: Colors.transparent,
      bodyPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Add horizontal padding to body
    );

    // Define image/icon widgets
    const double iconSize = 150; // Define a size for the icons
    final Widget logoImage = Padding(
      padding: const EdgeInsets.only(
        bottom: 20.0,
      ), // Add some padding below image
      child: Image.asset(
        'assets/images/onbourding-icon.png', // Use the specified image path
        height: 250, // Adjust height as needed
      ),
    );

    final Widget calculatorIcon = Icon(
      LucideIcons.calculator,
      size: iconSize,
      color: colorScheme.primary,
    );

    final Widget interactionsIcon = Icon(
      LucideIcons.zap, // Icon for interactions
      size: iconSize,
      color: colorScheme.primary,
    );

    final Widget alternativesIcon = Icon(
      LucideIcons.replace, // Icon for alternatives
      size: iconSize,
      color: colorScheme.primary,
    );

    // Corrected IntroductionScreen structure
    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(),
      globalBackgroundColor: colorScheme.background,
      allowImplicitScrolling: true,
      autoScrollDuration: null,

      pages: [
        PageViewModel(
          title: isArabic ? "مرحباً بك في MediSwitch" : "Welcome to MediSwitch",
          body:
              isArabic
                  ? "دليلك الشامل للأدوية في مصر. ابحث بسهولة عن الأدوية، بدائلها، أسعارها، والمزيد."
                  : "Your comprehensive guide to medicines in Egypt. Easily search for medicines, alternatives, prices, and more.",
          image: logoImage, // Use the logo widget for the first page
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: isArabic ? "حاسبة الجرعات الذكية" : "Smart Dose Calculator",
          body:
              isArabic
                  ? "احسب الجرعات بدقة بناءً على وزن وعمر المريض لأدوية الأطفال الشائعة."
                  : "Calculate doses accurately based on patient weight and age for common pediatric medications.",
          image: calculatorIcon, // Use the calculator icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title:
              isArabic
                  ? "مدقق التفاعلات الدوائية"
                  : "Drug Interactions Checker",
          body:
              isArabic
                  ? "تجنب التفاعلات الخطيرة بين الأدوية عن طريق فحص قائمة الأدوية الخاصة بك."
                  : "Avoid dangerous drug interactions by checking your medication list.",
          image: interactionsIcon, // Use the interactions icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title:
              isArabic
                  ? "البدائل والمواد الفعالة"
                  : "Alternatives & Active Ingredients",
          body:
              isArabic
                  ? "اعثر بسهولة على بدائل الأدوية المتاحة بنفس المادة الفعالة."
                  : "Easily find available drug alternatives with the same active ingredient.",
          image: alternativesIcon, // Use the alternatives icon
          decoration: pageDecoration,
        ),
      ],

      onDone: () => _onOnboardingComplete(context),
      onSkip: () => _onOnboardingComplete(context),
      showSkipButton: true,
      skip: Text(
        isArabic ? 'تخطي' : 'Skip',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      next: Icon(LucideIcons.arrowRight, color: colorScheme.primary),
      done: Text(
        isArabic ? 'تم' : 'Done',
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
    );
  }

  // Removed _buildImage helper as we use Image.asset directly now
}
