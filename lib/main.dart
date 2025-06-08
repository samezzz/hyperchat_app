import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hyperchat_app/providers/user_provider.dart';
import 'package:hyperchat_app/common/theme_provider.dart';
import 'package:hyperchat_app/common/app_theme.dart';
import 'package:hyperchat_app/view/splash/splash_view.dart';
import 'package:hyperchat_app/view/welcome/welcome_view.dart';
import 'package:hyperchat_app/view/auth/register_view.dart';
import 'package:hyperchat_app/view/auth/login_view.dart';
import 'package:hyperchat_app/view/onboarding/onboarding_view.dart';
import 'package:hyperchat_app/view/main_tab/main_tab_view.dart';
import 'package:hyperchat_app/view/profile/profile_view.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashView(),
              '/welcome': (context) => const WelcomeView(),
              '/register': (context) => const RegisterView(),
              '/login': (context) => const LoginView(),
              '/onboarding': (context) => const OnboardingView(),
              '/home': (context) => const MainTabView(),
              '/profile': (context) => const ProfileView(),
            },
          );
        },
      ),
    );
  }
}