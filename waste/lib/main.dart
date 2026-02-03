import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize push notifications
  await NotificationService().initialize();
  // Load theme preference
  await ThemeController.instance.load();

  runApp(WasteWiseApp(themeController: ThemeController.instance));
}

class WasteWiseApp extends StatelessWidget {
  const WasteWiseApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController.themeMode,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WasteWise Connect',
          themeMode: themeController.themeMode.value,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}
