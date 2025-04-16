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
          title: "مرحباً بك في MediSwitch",
          body:
              "دليلك الشامل للأدوية في مصر. ابحث بسهولة عن الأدوية، بدائلها، أسعارها، والمزيد.",
          image: logoImage, // Use the logo widget for the first page
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "حاسبة الجرعات الذكية",
          body:
              "احسب الجرعات بدقة بناءً على وزن وعمر المريض لأدوية الأطفال الشائعة.",
          image: calculatorIcon, // Use the calculator icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "مدقق التفاعلات الدوائية",
          body:
              "تجنب التفاعلات الخطيرة بين الأدوية عن طريق فحص قائمة الأدوية الخاصة بك.",
          image: interactionsIcon, // Use the interactions icon
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "البدائل والمواد الفعالة",
          body: "اعثر بسهولة على بدائل الأدوية المتاحة بنفس المادة الفعالة.",
          image: alternativesIcon, // Use the alternatives icon
          decoration: pageDecoration,
        ),
      ],

      onDone: () => _onOnboardingComplete(context),
      onSkip: () => _onOnboardingComplete(context),
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
    );
  }

  // Removed _buildImage helper as we use Image.asset directly now
}
