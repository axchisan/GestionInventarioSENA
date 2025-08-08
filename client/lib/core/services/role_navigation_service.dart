import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleNavigationService {
  static void navigateByRole(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'student':
        context.go('/student-dashboard');
        break;
      case 'instructor':
        context.go('/instructor-dashboard');
        break;
      case 'supervisor':
        context.go('/supervisor-dashboard');
        break;
      case 'admin':
        context.go('/admin-dashboard');
        break;
      case 'admin_general':
        context.go('/admin-general-dashboard');
        break;
      default:
        context.go('/login');
    }
  }

  static List<String> getAvailableRoutes(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return [
          '/student-dashboard',
          '/qr-scan',
          '/loan-request',
          '/loan-history',
          '/inventory-check',
          '/notifications',
          '/profile',
          '/settings',
        ];
      case 'instructor':
        return [
          '/instructor-dashboard',
          '/inventory-check',
          '/qr-scan',
          '/loan-history',
          '/maintenance-request',
          '/inventory-history',
          '/environment-overview',
          '/training-schedule',
          '/notifications',
          '/profile',
          '/settings',
        ];
      case 'supervisor':
        return [
          '/supervisor-dashboard',
          '/user-management',
          '/statistics-dashboard',
          '/inventory-alerts',
          '/audit-log',
          '/report-generator',
          '/training-schedule',
          '/notifications',
          '/profile',
          '/settings',
        ];
      case 'admin':
        return [
          '/admin-dashboard',
          '/user-management',
          '/statistics-dashboard',
          '/inventory-alerts',
          '/audit-log',
          '/report-generator',
          '/feedback-form',
          '/notifications',
          '/profile',
          '/settings',
          '/qr-scan',
          '/inventory-check',
          '/loan-request',
          '/loan-history',
          '/maintenance-request',
          '/inventory-history',
          '/environment-overview',
          '/training-schedule',
        ];
      case 'admin_general':
        return [
          '/admin-general-dashboard',
          '/user-management',
          '/statistics-dashboard',
          '/inventory-alerts',
          '/audit-log',
          '/report-generator',
          '/feedback-form',
          '/notifications',
          '/profile',
          '/settings',
          '/qr-scan',
          '/inventory-check',
          '/loan-request',
          '/loan-history',
          '/maintenance-request',
          '/inventory-history',
          '/environment-overview',
          '/training-schedule',
          '/admin-dashboard', // Acceso a todas las rutas de admin
        ];
      default:
        return ['/login', '/register'];
    }
  }

  static bool hasAccessToRoute(String role, String route) {
    final availableRoutes = getAvailableRoutes(role);
    return availableRoutes.contains(route);
  }

  static String getDefaultRoute(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return '/student-dashboard';
      case 'instructor':
        return '/instructor-dashboard';
      case 'supervisor':
        return '/supervisor-dashboard';
      case 'admin':
        return '/admin-dashboard';
      case 'admin_general':
        return '/admin-general-dashboard';
      default:
        return '/login';
    }
  }
}