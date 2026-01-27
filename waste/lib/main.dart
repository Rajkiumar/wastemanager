import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import './main_shell.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

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
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
            brightness: Brightness.dark,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
