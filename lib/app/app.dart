import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/notifications/notifications_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class HeyFansApp extends StatelessWidget {
  const HeyFansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hey Fans',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: HeyTheme.lightTheme,
      darkTheme: HeyTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.editProfile: (context) => const EditProfileScreen(),
        AppRoutes.blockedUsers: (context) => const BlockedUsersScreen(),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
      },
    );
  }
}
