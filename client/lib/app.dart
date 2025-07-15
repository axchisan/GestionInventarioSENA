import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/services/navigation_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

class SenaApp extends StatelessWidget {
  const SenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp.router(
          title: 'SENA Inventory',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          routerConfig: NavigationService.router,
        );
      },
    );
  }
}

// ignore: unused_element
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // Rutas desactivadas temporalmente
    /*
    GoRoute(path: '/home', name: 'home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/qr-scan', name: 'qr-scan', builder: (context, state) => const QRScanScreen()),
    GoRoute(path: '/inventory-check', name: 'inventory-check', builder: (context, state) => const InventoryCheckScreen()),
    GoRoute(path: '/supervisor-dashboard', name: 'supervisor-dashboard', builder: (context, state) => const SupervisorDashboard()),
    GoRoute(path: '/loan-request', name: 'loan-request', builder: (context, state) => const LoanRequestScreen()),
    GoRoute(path: '/admin-dashboard', name: 'admin-dashboard', builder: (context, state) => const AdminDashboard()),
    GoRoute(path: '/statistics', name: 'statistics', builder: (context, state) => const StatisticsDashboard()),
    GoRoute(path: '/maintenance-request', name: 'maintenance-request', builder: (context, state) => const MaintenanceRequestScreen()),
    GoRoute(path: '/notifications', name: 'notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
    */
  ],
);