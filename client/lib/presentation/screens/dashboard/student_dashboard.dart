import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late final ApiService _apiService;
  Map<String, dynamic>? _environment;
  Map<String, dynamic>? _inventoryStats;
  bool _isLoading = true; // Agregado para manejar loading

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _fetchData(); // Fetch inicial
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.environmentId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincula un ambiente primero escaneando QR')),
      );
      return;
    }
    try {
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
        title: 'Panel de Aprendiz',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Agregado para refresh manual
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
                                color: AppColors.primary.withOpacity(0.1),
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
                                    '¡Bienvenido, ${user?.firstName ?? 'Aprendiz'}!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _environment != null
                                        ? 'Ambiente: ${_environment!['name']} (${_environment!['location']})'
                                        : 'Escanea un QR para vincular un ambiente',
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
                      'Resumen Rápido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Disponibles',
                              _inventoryStats!['available'].toString(),
                              Icons.check_circle,
                              AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'En Uso',
                              _inventoryStats!['in_use'].toString(),
                              Icons.assignment,
                              AppColors.warning,
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
                        'Vincula un ambiente para ver estadísticas',
                        style: TextStyle(color: AppColors.grey600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Acciones Disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          'Vincula un ambiente',
                          Icons.qr_code_scanner,
                          AppColors.primary,
                          '/qr-scan',
                        ),
                        _buildActionCard(
                          context,
                          'Verificar Inventario',
                          'Reporta estado diario',
                          Icons.checklist,
                          AppColors.secondary,
                          '/inventory-check',
                        ),
                        _buildActionCard(
                          context,
                          'Solicitar Préstamo',
                          'Pide equipos disponibles',
                          Icons.assignment_add,
                          AppColors.secondary,
                          '/loan-request',
                        ),
                        _buildActionCard(
                          context,
                          'Mis Préstamos',
                          'Consulta préstamos activos',
                          Icons.assignment,
                          AppColors.accent,
                          '/loan-history',
                        ),
                        _buildActionCard(
                          context,
                          'Ambiente Overview',
                          'Vista del ambiente vinculado',
                          Icons.location_on,
                          AppColors.success,
                          _environment != null ? '/environment-overview' : '/qr-scan',
                          extra: _environment != null
                              ? {
                                  'environmentId': _environment!['id'],
                                  'environmentName': _environment!['name'],
                                }
                              : null,
                        ),
                        _buildActionCard(
                          context,
                          'Notificaciones',
                          'Revisa alertas',
                          Icons.notifications,
                          AppColors.warning,
                          '/notifications',
                        ),
                        _buildActionCard(
                          context,
                          'Mi Perfil',
                          'Actualiza información',
                          Icons.person,
                          AppColors.success,
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
                              'Alertas Recientes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAlertItem('Verificación pendiente hoy', 'Ambiente 101', AppColors.warning),
                            _buildAlertItem('Préstamo próximo a vencer', 'Laptop Dell', AppColors.error),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/notifications'),
                              child: const Text('Ver todas las alertas'),
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

  // Los métodos _buildStatCard, _buildActionCard, _buildAlertItem y _buildDrawer son idénticos a los del original, pero ajustados para student (sin generar QR).


  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    // Igual al original
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
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
    String route, {
    Map<String, dynamic>? extra,
  }) {
    // Igual al original, con soporte para extra (para environment-overview)
    return Card(
      child: InkWell(
        onTap: () => context.push(route, extra: extra),
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, Color statusColor) {
    // Igual al original
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
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // Igual al original, pero ajustado para acciones de student (sin generar QR)
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
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
                  'Panel de Aprendiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'aprendiz@sena.edu.co',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/student-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear QR'),
            onTap: () => context.push('/qr-scan'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Verificar Inventario'),
            onTap: () => context.push('/inventory-check'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_add),
            title: const Text('Solicitar Préstamo'),
            onTap: () => context.push('/loan-request'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Mis Préstamos'),
            onTap: () => context.push('/loan-history'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Ambiente Overview'),
            onTap: () => context.push(
              '/environment-overview',
              extra: _environment != null
                  ? {
                      'environmentId': _environment!['id'],
                      'environmentName': _environment!['name'],
                    }
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () => context.push('/profile'),
          ),
          const Divider(),
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