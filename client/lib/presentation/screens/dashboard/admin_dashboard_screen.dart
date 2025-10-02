import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_management_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserManagementService _userService = UserManagementService();
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _userService.getDashboardStats();
      setState(() {
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Fallback to default values if API fails
      _dashboardStats = {
        'inventory': {
          'total_items': 0,
          'total_quantity': 0,
          'available_items': 0,
          'damaged_items': 0,
        },
        'maintenance': {'total_active': 0},
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Panel de Administrador de Almacen',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/sena_logo.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido, Administrador de Almacen!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Control total de inventario de Almacen SENA',
                              style: TextStyle(
                                color: AppColors.grey600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Métricas del Sistema',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Equipos',
                                '${_dashboardStats?['inventory']?['total_quantity'] ?? 0}',
                                Icons.inventory,
                                AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Items Únicos',
                                '${_dashboardStats?['inventory']?['total_items'] ?? 0}',
                                Icons.category,
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Disponibles',
                                '${_dashboardStats?['inventory']?['available_items'] ?? 0}',
                                Icons.check_circle,
                                AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'En Uso',
                                '${_dashboardStats?['inventory']?['in_use_items'] ?? 0}',
                                Icons.assignment,
                                AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Dañados',
                                '${_dashboardStats?['inventory']?['damaged_quantity'] ?? 0}',
                                Icons.warning,
                                AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Mantenimiento',
                                '${_dashboardStats?['maintenance']?['total_active'] ?? 0}',
                                Icons.build,
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              const Text(
                'Panel de Administración',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildActionCard(
                    context,
                    'Historial de Préstamos',
                    'Gestionar historial de préstamos',
                    Icons.history,
                    AppColors.secondary,
                    '/loan-history',
                  ),
                  _buildActionCard(
                    context,
                    'Gestión de Préstamos',
                    'Administrar todos los préstamos',
                    Icons.assignment_turned_in,
                    AppColors.secondary,
                    '/loan-management',
                  ),
                  _buildActionCard(
                    context,
                    'Gestión de Almacen',
                    'Administrar items del almacen',
                    Icons.home_work,
                    AppColors.secondary,
                    '/environment-overview',
                  ),
                  _buildActionCard(
                    context,
                    'Escáner QR',
                    'Escanear códigos QR para inventario',
                    Icons.qr_code_scanner,
                    AppColors.primary,
                    '/qr-scan',
                  ),
                  _buildActionCard(
                    context,
                    'Generador QR',
                    'Crear códigos QR para equipos o ambientes',
                    Icons.qr_code,
                    AppColors.primary,
                    '/qr-generator',
                  ),
                  _buildActionCard(
                    context,
                    'Estadísticas Avanzadas',
                    'Métricas y análisis detallados',
                    Icons.analytics,
                    AppColors.secondary,
                    '/statistics-dashboard',
                  ),
                  _buildActionCard(
                    context,
                    'Alertas del Sistema',
                    'Monitoreo de alertas críticas',
                    Icons.warning,
                    AppColors.warning,
                    '/inventory-alerts',
                  ),
                  _buildActionCard(
                    context,
                    'Generador de Reportes',
                    'Reportes personalizados avanzados',
                    Icons.description,
                    AppColors.success,
                    '/report-generator',
                  ),
                  _buildActionCard(
                    context,
                    'Feedback del Sistema',
                    'Comentarios y sugerencias',
                    Icons.feedback,
                    AppColors.accent,
                    '/feedback-form',
                  ),
                  _buildActionCard(
                    context,
                    'Configuración',
                    'Ajusta tu perfil y preferencias',
                    Icons.settings,
                    AppColors.primary,
                    '/profile',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del Sistema',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isLoading && _dashboardStats != null) ...[
                        _buildSystemStatusItem(
                          'Verificaciones Recientes',
                          '${_dashboardStats?['verifications']?['recent_checks'] ?? 0} en 30 días',
                          AppColors.info,
                        ),
                        _buildSystemStatusItem(
                          'Tasa de Completitud',
                          '${_dashboardStats?['verifications']?['completion_rate'] ?? 0}%',
                          (_dashboardStats?['verifications']?['completion_rate'] ??
                                      0) >=
                                  80
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        _buildSystemStatusItem(
                          'Items Faltantes',
                          '${_dashboardStats?['inventory']?['missing_quantity'] ?? 0}',
                          (_dashboardStats?['inventory']?['missing_quantity'] ??
                                      0) >
                                  0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        _buildSystemStatusItem(
                          'Mantenimiento Pendiente',
                          '${_dashboardStats?['maintenance']?['pending_requests'] ?? 0} solicitudes',
                          (_dashboardStats?['maintenance']?['pending_requests'] ??
                                      0) >
                                  5
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatusItem(
    String component,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              component,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.error),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/sena_logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Panel de Administrador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'admin@sena.edu.co',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/admin-dashboard-screen'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Préstamos'),
            onTap: () => context.push('/loan-history'),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Gestión de Préstamos'),
            onTap: () => context.push('/loan-management'),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('gestión de Almacen'),
            onTap: () => context.push('/environment-overview'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escáner QR'),
            onTap: () => context.push('/qr-scan'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Generador QR'),
            onTap: () => context.push('/qr-generate'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Estadísticas'),
            onTap: () => context.push('/statistics-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Alertas'),
            onTap: () => context.push('/inventory-alerts'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Reportes'),
            onTap: () => context.push('/report-generator'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback'),
            onTap: () => context.push('/feedback-form'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () => context.push('/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
