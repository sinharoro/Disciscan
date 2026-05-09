import 'package:go_router/go_router.dart';
import '../db/models/scan_log.dart';
import '../screens/scan_screen.dart';
import '../screens/result_screen.dart';
import '../screens/log_screen.dart';
import '../screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final scanLog = state.extra as ScanLog;
        return ResultScreen(scanLog: scanLog);
      },
    ),
    GoRoute(
      path: '/log',
      builder: (context, state) => const LogScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);