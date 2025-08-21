import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  late final ApiService _apiService;
  Map<String, dynamic>? _environment;
  Map<String, dynamic>? _inventoryStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    try {
      if (user?.environmentId != null) {
        final environment = await _apiService.getSingle(
          '$environmentsEndpoint${user!.environmentId}',
        );
        final items = await _apiService.get(
          inventoryEndpoint,
          queryParams: {'environment_id': user.environmentId.toString()},
        );
        setState(() {
          _environment = environment;
          _inventoryStats = {
            'total': items.length,
            'available': items.where((item) => item['status'] == 'available').length,
            'in_use': items.where((item) => item['status'] == 'in_use').length,
            'maintenance': items.where((item) => item['status'] == 'maintenance').length,
          };
        });
      } else {
        // Para supervisor sin ambiente específico, fetch general o de todos ambientes (ajustar si backend lo soporta)
        final items = await _apiService.get(inventoryEndpoint); // Asume endpoint soporta sin environment_id para supervisor
        setState(() {
          _inventoryStats = {
            'total': items.length,
            'available': items.where((item) => item['status'] == 'available').length,
            'in_use': items.where((item) => item['status'] == 'in_use').length,
            'maintenance': items.where((item) => item['status'] == 'maintenance').length,
          };
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Panel de Supervisor',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
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
                                color: AppColors.accent.withOpacity(0.1),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Bienvenido, ${user?.firstName ?? 'Supervisor'}!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _environment != null
                                        ? 'Ambiente Vinculado: ${_environment!['name']}'
                                        : 'Vincula un ambiente o supervisa general',
                                    style: const TextStyle(
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
                      'Resumen de Supervisión',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_inventoryStats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Equipos Totales',
                              _inventoryStats!['total'].toString(),
                              Icons.inventory,
                              AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Pendientes',
                              '15', // Esto podría fetch de otro endpoint, pero por ahora hardcoded; ajusta si necesitas
                              Icons.pending_actions,
                              AppColors.warning,
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
                              _inventoryStats!['available'].toString(),
                              Icons.check_circle,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Mantenimiento',
                              _inventoryStats!['maintenance'].toString(),
                              Icons.build,
                              AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'No hay data disponible; vincula un ambiente',
                        style: TextStyle(color: AppColors.grey600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Panel de Control',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                          context,
                          'Escanear QR',
                          'Vincula ambiente para supervisar',
                          Icons.qr_code_scanner,
                          AppColors.primary,
                          '/qr-scan',
                        ),
                        _buildActionCard(
                          context,
                          'Generar QR',
                          'Crea QR para items/ambientes',
                          Icons.qr_code,
                          AppColors.accent,
                          '/qr-generate',
                        ),
                        _buildActionCard(
                          context,
                          'Verificar Inventario',
                          'Revisa y aprueba checks',
                          Icons.checklist,
                          AppColors.secondary,
                          '/inventory-check',
                        ),
                        _buildActionCard(
                          context,
                          'Ambiente Overview',
                          'Supervisa ambiente vinculado',
                          Icons.location_on,
                          AppColors.success,
                          _environment != null ? '/environment-overview' : '/qr-scan',
                        ),
                        _buildActionCard(
                          context,
                          'Gestión de Usuarios',
                          'Administra usuarios',
                          Icons.people,
                          AppColors.primary,
                          '/user-management',
                        ),
                        _buildActionCard(
                          context,
                          'Estadísticas',
                          'Reportes generales',
                          Icons.analytics,
                          AppColors.secondary,
                          '/statistics-dashboard',
                        ),
                        _buildActionCard(
                          context,
                          'Alertas de Inventario',
                          'Monitorea alertas',
                          Icons.warning,
                          AppColors.warning,
                          '/inventory-alerts',
                        ),
                        _buildActionCard(
                          context,
                          'Historial de Auditoría',
                          'Registro de actividades',
                          Icons.history,
                          AppColors.info,
                          '/audit-log',
                        ),
                        _buildActionCard(
                          context,
                          'Generar Reportes',
                          'Crea reportes',
                          Icons.description,
                          AppColors.success,
                          '/report-generator',
                        ),
                        _buildActionCard(
                          context,
                          'Cronograma General',
                          'Horarios programados',
                          Icons.schedule,
                          AppColors.primary,
                          '/training-schedule',
                        ),
                        _buildActionCard(
                          context,
                          'Notificaciones',
                          'Revisa alertas',
                          Icons.notifications,
                          AppColors.error,
                          '/notifications',
                        ),
                        _buildActionCard(
                          context,
                          'Configuración',
                          'Ajustes del sistema',
                          Icons.settings,
                          AppColors.grey600,
                          '/settings',
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
                              'Solicitudes Pendientes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPendingItem('Préstamo pendiente', 'Instructor X - Ambiente 101', AppColors.warning),
                            _buildPendingItem('Mantenimiento', 'Item dañado en Ambiente 205', AppColors.error),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/inventory-alerts'), // Ajustado a alertas
                              child: const Text('Ver todas las solicitudes'),
                            ),
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
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
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

  Widget _buildPendingItem(String title, String subtitle, Color statusColor) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.grey400, size: 16),
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
            decoration: const BoxDecoration(color: AppColors.accent),
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
                  'Panel de Supervisor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'supervisor@sena.edu.co',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/supervisor-dashboard-screen'),
          ),
          ListTile(
            leading: const Icon(Icons.supervisor_account),
            title: const Text('Panel Supervisor'),
            onTap: () => context.push('/supervisor-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestión de Usuarios'),
            onTap: () => context.push('/user-management'),
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
            leading: const Icon(Icons.history),
            title: const Text('Auditoría'),
            onTap: () => context.push('/audit-log'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () => context.push('/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}