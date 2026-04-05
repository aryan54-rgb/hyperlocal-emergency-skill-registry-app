// ============================================================
// MAIN.DART - App entry point
// Hyperlocal Emergency Skill Registry System
//
// Architecture: MVVM + Provider
// Clean structure: core / models / viewmodels / views / widgets
//
// ============================================================
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'viewmodels/app_settings_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';
import 'views/onboarding_screen.dart';
import 'views/home_screen.dart';
import 'views/register_screen.dart';
import 'views/search_screen.dart';
import 'views/emergency_request_screen.dart';
import 'views/map_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/settings_screen.dart';

Widget _buildMapRoute() => ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: const MapScreen(),
    );

class _RuntimeConfig {
  final String supabaseUrl;
  final String supabasePublishableKey;

  const _RuntimeConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });
}

Future<_RuntimeConfig> _loadRuntimeConfig() async {
  const envUrl = String.fromEnvironment('SUPABASE_URL');
  const envKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (envUrl.isNotEmpty && envKey.isNotEmpty) {
    return const _RuntimeConfig(
      supabaseUrl: envUrl,
      supabasePublishableKey: envKey,
    );
  }

  final fileValues = await _loadDotEnvAsset();
  final fileUrl = fileValues['SUPABASE_URL'] ?? '';
  final fileKey = fileValues['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  if (fileUrl.isNotEmpty && fileKey.isNotEmpty) {
    return _RuntimeConfig(
      supabaseUrl: fileUrl,
      supabasePublishableKey: fileKey,
    );
  }

  throw StateError(
    'Missing Supabase configuration. Provide --dart-define values or create '
    'a local .env file with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
  );
}

Future<Map<String, String>> _loadDotEnvAsset() async {
  try {
    final raw = await rootBundle.loadString('.env');
    final values = <String, String>{};

    for (final originalLine in raw.split('\n')) {
      final line = originalLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      values[key] = value;
    }

    return values;
  } catch (_) {
    return const {};
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final message = details.exceptionAsString();

    // Layout overflows are non-fatal framework errors in debug/profile and
    // should not replace the running app with the startup failure screen.
    if (message.contains('A RenderFlex overflowed by')) {
      debugPrint('[FlutterError][layout] $message');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[FlutterError] $message');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
      return;
    }

    runApp(_StartupFailureApp(
      message: message,
      details: details.stack?.toString(),
    ));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[PlatformError] $error');
      debugPrint(stack.toString());
      return true;
    }

    runApp(_StartupFailureApp(
      message: error.toString(),
      details: stack.toString(),
    ));
    return true;
  };

  try {
    final runtimeConfig = await _loadRuntimeConfig();

    await Supabase.initialize(
      url: runtimeConfig.supabaseUrl,
      anonKey: runtimeConfig.supabasePublishableKey,
    );

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
  } catch (error, stack) {
    runApp(_StartupFailureApp(
      message: error.toString(),
      details: stack.toString(),
    ));
  }
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
        '/emergency-request': (_) => const EmergencyRequestScreen(),
        '/map': (_) => _buildMapRoute(),
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
              case '/emergency-request':
                return const EmergencyRequestScreen();
              case '/map':
                return _buildMapRoute();
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

class _StartupFailureApp extends StatelessWidget {
  final String message;
  final String? details;

  const _StartupFailureApp({
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App startup failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(message),
                    if (details != null && details!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      if (kDebugMode)
                        SelectableText(
                          details!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
