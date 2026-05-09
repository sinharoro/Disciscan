import 'dart:io'; // Added for platform check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Added for FFI
import 'package:sqflite/sqflite.dart'; // Added to access databaseFactory
import 'db/database_helper.dart';
import 'providers/settings_provider.dart';
import 'router.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Desktop (Windows, macOS, Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // This will now work on desktop because the factory is initialized above
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: DisciScanApp()));
}

class DisciScanApp extends ConsumerStatefulWidget {
  const DisciScanApp({super.key});

  @override
  ConsumerState<DisciScanApp> createState() => _DisciScanAppState();
}

class _DisciScanAppState extends ConsumerState<DisciScanApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DisciScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
