// ============================================================
// MAIN.DART - App entry point
// Hyperlocal Emergency Skill Registry System
//
// Architecture: MVVM + Provider
// Clean structure: core / models / viewmodels / views / widgets
// ============================================================
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'viewmodels/app_settings_viewmodel.dart';
import 'views/onboarding_screen.dart';
import 'views/home_screen.dart';
import 'views/register_screen.dart';
import 'views/search_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw ArgumentError(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
      'Run with --dart-define for both values.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkBg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone =
      prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

  final settingsVm = AppSettingsViewModel();
  await settingsVm.loadPreferences();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsVm,
      child: EmergencyRegistryApp(showOnboarding: !onboardingDone),
    ),
  );
}


class EmergencyRegistryApp extends StatelessWidget {
  final bool showOnboarding;

  const EmergencyRegistryApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsViewModel>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ---- Theme selection based on settings ----
      theme: settings.isDarkMode
          ? AppTheme.dark(
              highContrast: settings.highContrast,
              largeText: settings.largeText,
            )
          : AppTheme.light(
              largeText: settings.largeText,
            ),

      // ---- Text scaling for accessibility ----
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScaleFactor),
          ),
          child: child!,
        );
      },

      // ---- Initial route ----
      initialRoute: showOnboarding ? '/onboarding' : '/home',

      // ---- Named routes ----
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
        '/register': (_) => const RegisterScreen(),
        '/search': (_) => const SearchScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
      },

      // ---- Page transitions ----
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            switch (settings.name) {
              case '/onboarding':
                return const OnboardingScreen();
              case '/home':
                return const HomeScreen();
              case '/register':
                return const RegisterScreen();
              case '/search':
                return const SearchScreen();
              case '/dashboard':
                return const DashboardScreen();
              case '/settings':
                return const SettingsScreen();
              default:
                return const HomeScreen();
            }
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth fade + slight upward slide for all page transitions
            final fadeAnim = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final slideAnim = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(position: slideAnim, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    );
  }
}
