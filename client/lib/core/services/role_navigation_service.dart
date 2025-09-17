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
          '/maintenance-request',
          '/notifications',
          '/profile',
          '/settings',
          '/environment-overview',
        ];
      case 'instructor':
        return [
          '/instructor-dashboard',
          '/inventory-check',
          '/manage-schedules',
          '/qr-scan',
          '/qr-generate',
          '/loan-history',
          '/loan-request',
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
          '/inventory-check',
          '/manage-schedules',
          '/audit-log',
          '/report-generator',
          '/training-schedule',
          '/notifications',
          '/profile',
          '/settings',
          '/qr-generate',
          '/environment-overview',
          '/qr-scan',
          '/add-inventory-item', 
          '/edit-inventory-item', 
        ];
      case 'admin':
        return [
          '/admin-dashboard',
          '/user-management',
          '/manage-schedules',
          '/statistics-dashboard',
          '/inventory-alerts',
          '/audit-log',
          '/report-generator',
          '/feedback-form',
          '/notifications',
          '/profile',
          '/settings',
          '/qr-scan',
          '/qr-generate',
          '/inventory-check',
          '/loan-request',
          '/loan-management',
          '/loan-history',
          '/maintenance-request',
          '/inventory-history',
          '/environment-overview',
          '/training-schedule',
          '/add-inventory-item', 
          '/edit-inventory-item', 
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
          '/qr-generate',
          '/inventory-check',
          '/manage-schedules',
          '/loan-request',
          '/loan-history',
          '/loan-management',
          '/maintenance-request',
          '/inventory-history',
          '/environment-overview',
          '/training-schedule',
          '/admin-dashboard',
          '/add-inventory-item',
          '/edit-inventory-item',
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

  // Función personalizable para definir roles por vista
  static Map<String, List<String>> defineRoutePermissions() {
    return {
      '/student-dashboard': ['student'],
      '/instructor-dashboard': ['instructor'],
      '/supervisor-dashboard': ['supervisor'],
      '/admin-dashboard': ['admin'],
      '/admin-general-dashboard': ['admin_general'],
      '/user-management': ['supervisor', 'admin', 'admin_general'],
      '/statistics-dashboard': ['supervisor', 'admin', 'admin_general'],
      '/inventory-alerts': ['supervisor', 'admin', 'admin_general'],
      '/audit-log': ['supervisor', 'admin', 'admin_general'],
      '/report-generator': ['supervisor', 'admin', 'admin_general'],
      '/feedback-form': ['admin', 'admin_general'],
      '/qr-scan': ['student', 'instructor', 'admin', 'admin_general', 'supervisor'],
      '/qr-generate': ['supervisor', 'instructor', 'admin', 'admin_general'],
      '/inventory-check': ['student', 'instructor', 'admin', 'admin_general', 'supervisor'],
      '/loan-request': ['instructor', 'admin', 'admin_general'],
      '/loan-history': ['student', 'instructor', 'admin', 'admin_general'],
      '/loan-management': ['admin', 'admin_general'],
      '/maintenance-request': ['student', 'instructor', 'admin', 'admin_general'],
      '/inventory-history': ['instructor', 'admin', 'admin_general'],
      '/environment-overview': ['instructor', 'admin', 'admin_general', 'student'],
      '/training-schedule': ['instructor', 'supervisor', 'admin', 'admin_general'],
      '/notifications': ['student', 'instructor', 'supervisor', 'admin', 'admin_general'],
      '/profile': ['student', 'instructor', 'supervisor', 'admin', 'admin_general'],
      '/settings': ['student', 'instructor', 'supervisor', 'admin', 'admin_general'],
      '/add-inventory-item': ['supervisor', 'admin', 'admin_general'],
      '/edit-inventory-item': ['supervisor', 'admin', 'admin_general'],
      '/manage-schedules': ['instructor', 'supervisor', 'admin', 'admin_general'],
    };
  }

  static bool checkRoutePermission(String role, String route) {
    final permissions = defineRoutePermissions();
    final allowedRoles = permissions[route] ?? [];
    return allowedRoles.isEmpty || allowedRoles.contains(role.toLowerCase());
  }
}