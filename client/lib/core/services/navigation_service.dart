// navigation_service.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/role_navigation_service.dart';
import '../../core/services/session_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/dashboard/general_admin_dashboard_screen.dart';
import '../../presentation/screens/environment/manage_schedules_screen.dart';
import '../../presentation/screens/inventory/AddInventoryItemScreen.dart';
import '../../presentation/screens/inventory/edit_inventory_item_screen.dart';
import '../../presentation/screens/qr/qr_code_generator_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/admin/user_management_screen.dart';
import '../../presentation/screens/audit/audit_log_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/dashboard/admin_dashboard_screen.dart';
import '../../presentation/screens/dashboard/instructor_dashboard.dart';
import '../../presentation/screens/dashboard/student_dashboard.dart';
import '../../presentation/screens/dashboard/supervisor_dashboard_screen.dart';
import '../../presentation/screens/environment/environment_overview_screen.dart';
import '../../presentation/screens/feedback/feedback_form_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/inventory/inventory_alerts_screen.dart';
import '../../presentation/screens/inventory/inventory_check_screen.dart';
import '../../presentation/screens/inventory/inventory_history_screen.dart';
import '../../presentation/screens/loan/loan_history_screen.dart';
import '../../presentation/screens/loan/loan_request_screen.dart';
import '../../presentation/screens/maintenance/maintenance_request_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/qr/qr_scan_screen.dart';
import '../../presentation/screens/reports/report_generator_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/statistics/statistics_dashboard.dart';
import '../../presentation/screens/training/training_schedule_screen.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = await authProvider.checkSession();
      final role = await SessionService.getRole();
      final currentPath = state.fullPath ?? '/';

      if (!isAuthenticated) {
        if (!['/login', '/register', '/splash'].contains(currentPath)) {
          return '/login';
        }
      } else if (role != null &&
          !RoleNavigationService.hasAccessToRoute(role, currentPath)) {
        return RoleNavigationService.getDefaultRoute(role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        path: '/qr-generate',
        name: 'qr-generate',
        builder: (context, state) => const QrCodeGeneratorScreen(),
      ),
      GoRoute(
        path: '/inventory-check',
        name: 'inventory-check',
        builder: (context, state) => const InventoryCheckScreen(),
      ),
      GoRoute(
        path: '/loan-request',
        name: 'loan-request',
        builder: (context, state) => const LoanRequestScreen(),
      ),
      GoRoute(
        path: '/maintenance-request',
        name: 'maintenance-request',
        builder: (context, state) => const MaintenanceRequestScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-general-dashboard',
        name: 'admin-general-dashboard',
        builder: (context, state) => const GeneralAdminDashboardScreen(),
      ),
      GoRoute(
        path: '/instructor-dashboard',
        name: 'instructor-dashboard',
        builder: (context, state) => const InstructorDashboard(),
      ),
      GoRoute(
        path: '/student-dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/supervisor-dashboard',
        name: 'supervisor-dashboard',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: '/statistics-dashboard',
        name: 'statistics-dashboard',
        builder: (context, state) => const StatisticsDashboard(),
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
        builder: (context, state) =>
            const InventoryHistoryScreen(itemId: '', itemName: ''),
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
        path: '/add-inventory-item',
        name: 'add-inventory-item',
        builder: (context, state) => const AddInventoryItemScreen(),
      ),
      GoRoute(
        path: '/edit-inventory-item',
        name: 'edit-inventory-item',
        builder: (context, state) =>
            EditInventoryItemScreen(item: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/manage-schedules',
        name: 'manage-schedules',
        builder: (context, state) => const ManageSchedulesScreen(),
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
    ],
  );

  static void navigateToRole(String role) {
    router.go(RoleNavigationService.getDefaultRoute(role));
  }
}
