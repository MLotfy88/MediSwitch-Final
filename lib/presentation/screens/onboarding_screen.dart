import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/locator.dart'; // Import locator to get SharedPreferences
import 'main_screen.dart'; // Import MainScreen to navigate to

const String _prefsKeyOnboardingDone = 'onboarding_complete';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Function called when Done or Skip button is pressed
  void _onIntroEnd(BuildContext context) async {
    // Mark onboarding as complete in SharedPreferences
    final prefs = await locator.getAsync<SharedPreferences>();
    await prefs.setBool(_prefsKeyOnboardingDone, true);

    // Navigate to the MainScreen and replace the onboarding screen
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
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
      skip: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text(
        'ابدأ الآن',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),

      // --- Dots Indicator ---
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        color: Colors.black26,
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
