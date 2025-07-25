import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
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
      GoRoute(path: '/admin-dashboard', name: 'admin-dashboard', builder: (context, state) => const AdminDashboard()),
      GoRoute(path: '/statistics', name: 'statistics', builder: (context, state) => const StatisticsDashboard()),
      GoRoute(path: '/notifications', name: 'notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
      */
    ],
  );

  static void navigateToRole(String role) {
    // Placeholder: Redirige según el rol (implementar rutas reales más adelante)
    switch (role.toLowerCase()) {
      case 'student':
      case 'instructor':
      case 'supervisor':
        // Por ahora, redirige a una pantalla de bienvenida genérica (a implementar)
        // Ejemplo: context.push('/home');
        break;
      default:
        // Redirige a login si el rol no es válido
        router.go('/login');
    }
  }
}