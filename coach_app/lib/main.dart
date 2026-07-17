import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage helper
  await LocalStorage.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check local storage to see if coach is already authenticated
    final token = LocalStorage.getToken();
    final profile = LocalStorage.getUserProfile();
    final isAuthenticated = token != null && profile != null;

    return MaterialApp(
      title: 'uSPORT Coach Command',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
