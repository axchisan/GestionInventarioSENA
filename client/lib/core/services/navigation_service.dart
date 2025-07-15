import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes
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
      // Rutas comentadas para activarlas modularmente
      /*
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/qr-scan',
        name: 'qr-scan',
        builder: (context, state) => const QRScanScreen(),
      ),
      GoRoute(
        path: '/inventory-check',
        name: 'inventory-check',
        builder: (context, state) => const InventoryCheckScreen(),
      ),
      GoRoute(
        path: '/supervisor-dashboard',
        name: 'supervisor-dashboard',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/statistics-dashboard',
        name: 'statistics-dashboard',
        builder: (context, state) => const StatisticsDashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/inventory-history',
        name: 'inventory-history',
        builder: (context, state) => const InventoryHistoryScreen(),
      ),
      GoRoute(
        path: '/loan-history',
        name: 'loan-history',
        builder: (context, state) => const LoanHistoryScreen(),
      ),
      GoRoute(
        path: '/environment-overview',
        name: 'environment-overview',
        builder: (context, state) => const EnvironmentOverviewScreen(),
      ),
      GoRoute(
        path: '/audit-log',
        name: 'audit-log',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/user-management',
        name: 'user-management',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/inventory-alerts',
        name: 'inventory-alerts',
        builder: (context, state) => const InventoryAlertsScreen(),
      ),
      GoRoute(
        path: '/training-schedule',
        name: 'training-schedule',
        builder: (context, state) => const TrainingScheduleScreen(),
      ),
      GoRoute(
        path: '/report-generator',
        name: 'report-generator',
        builder: (context, state) => const ReportGeneratorScreen(),
      ),
      GoRoute(
        path: '/feedback-form',
        name: 'feedback-form',
        builder: (context, state) => const FeedbackFormScreen(),
      ),
      */
    ],
  );
}