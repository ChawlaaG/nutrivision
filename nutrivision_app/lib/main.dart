import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'features/navigation/main_wrapper.dart';
import 'core/services/profile_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/review_service.dart';
import 'core/services/local_food_service.dart';

import 'features/onboarding/onboarding_wizard.dart';
import 'features/auth/login_screen.dart';
import 'features/welcome/welcome_screen.dart';

import 'core/errors/global_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = GlobalErrorHandler.errorBuilder as void Function(FlutterErrorDetails)?;
  // For async errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    GlobalErrorHandler.handleError(error, stack);
    return true;
  };

  String initialRoute = '/welcome';

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    await NotificationService().init();
    await ReviewService().init();
    await ReviewService().requestReviewIfAppropriate();
    
    // Initialize Local Food DB
    await LocalFoodService().loadDatabase();

    final profileService = ProfileService();
    final hasProfile = await profileService.hasCompletedOnboarding();
    final isLoggedIn = await profileService.isLoggedIn();

    debugPrint('DEBUG: Has Profile: $hasProfile, Is Logged In: $isLoggedIn');

    if (hasProfile) {
      initialRoute = isLoggedIn ? '/home' : '/login';
    }
    debugPrint('DEBUG: Initial Route set to: $initialRoute');
  } catch (e) {
    debugPrint('Initialization Error: $e');
    // Fallback is already set to '/welcome'
  }

  runApp(
    riverpod.ProviderScope(
      child: NutriVisionApp(initialRoute: initialRoute),
    ),
  );
}

class NutriVisionApp extends StatelessWidget {
  final String initialRoute;

  const NutriVisionApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingWizard(),
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const MainWrapper(),
      },
    );
  }
}
