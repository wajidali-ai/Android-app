import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/database/db_helper.dart';
import 'core/printing/printer_service.dart';
import 'core/sync/sync_service.dart';
import 'providers/billing_provider.dart';
import 'providers/bills_history_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/printer_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SQLite Database (Offline-first local store)
  await DbHelper.instance.database;

  // 2. Initialize Bluetooth Printer Service
  await PrinterService.instance.init();

  // 3. Initialize Supabase if credentials exist in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final supabaseUrl = prefs.getString(AppConstants.keySupabaseUrl);
  final supabaseAnonKey = prefs.getString(AppConstants.keySupabaseAnonKey);

  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Main] Supabase init failed: $e (App will operate fully offline)');
    }
  }

  // 4. Initialize Cloud Sync Service
  await SyncService.instance.init();

  runApp(const MashallahBillingApp());
}

class MashallahBillingApp extends StatelessWidget {
  const MashallahBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => BillsHistoryProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()..init()),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
