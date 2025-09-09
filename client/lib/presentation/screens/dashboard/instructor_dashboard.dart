import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/notification_badge.dart';
import '../../../core/services/notification_service.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late final ApiService _apiService; 
  Map<String, dynamic>? _environment;
  Map<String, dynamic>? _inventoryStats;
  List<Map<String, dynamic>> _recentNotifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchEnvironment(),
      _fetchInventoryStats(),
      _fetchNotifications(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchEnvironment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.environmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincula un ambiente primero')),
      );
      return;
    }
    try {
      final environment = await _apiService.getSingle(
        '$environmentsEndpoint${user!.environmentId}',
      );
      setState(() {
        _environment = environment;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ambiente: $e')),
      );
    }
  }

  Future<void> _fetchInventoryStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.environmentId == null) {
      return;
    }
    try {
      final items = await _apiService.get(
        inventoryEndpoint,
        queryParams: {'environment_id': user!.environmentId.toString()},
      );
      setState(() {
        _inventoryStats = {
          'total': items.length,
          'available': items.where((item) => item['status'] == 'available').length,
          'in_use': items.where((item) => item['status'] == 'in_use').length,
          'maintenance': items.where((item) => item['status'] == 'maintenance').length,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await NotificationService.getNotifications();
      final unreadCount = await NotificationService.getUnreadCount();
      
      setState(() {
        _recentNotifications = notifications.take(3).toList();
        _unreadNotificationsCount = unreadCount;
      });
    } catch (e) {
      print('Error al cargar notificaciones: $e');
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
      appBar: SenaAppBar(
        title: 'Panel de Instructor',
        showBackButton: false,
        actions: [
          NotificationBadge(
            onTap: () => context.push('/notifications'),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
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
                                color: AppColors.secondary.withOpacity(0.1),
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
                                    '¡Bienvenido, ${user?.firstName ?? 'Instructor'}!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
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
                      'Mi Ambiente de Formación',
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
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'En Préstamo',
                              _inventoryStats!['in_use'].toString(),
                              Icons.assignment,
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
                        'Vincula un ambiente para ver estadísticas',
                        style: TextStyle(color: AppColors.grey600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Gestión de Ambiente',
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
                          'Verificar Inventario',
                          'Actualiza estado de equipos',
                          Icons.checklist,
                          AppColors.secondary,
                          '/inventory-check',
                        ),
                        _buildActionCard(
                          context,
                          'Escanear QR',
                          'Identifica equipos rápidamente',
                          Icons.qr_code_scanner,
                          AppColors.primary,
                          '/qr-scan',
                        ),
                        _buildActionCard(
                          context,
                          'Generar QR',
                          'Crea códigos QR para equipos',
                          Icons.qr_code,
                          AppColors.accent,
                          '/qr-generate',
                        ),
                        _buildActionCard(
                          context,
                          'Préstamos Activos',
                          'Gestiona préstamos del ambiente',
                          Icons.assignment,
                          AppColors.accent,
                          '/loan-history',
                        ),
                        _buildActionCard(
                          context,
                          'Solicitar Mantenimiento',
                          'Reporta equipos dañados',
                          Icons.build_circle,
                          AppColors.warning,
                          '/maintenance-request',
                        ),
                        _buildActionCard(
                          context,
                          'Historial de Inventario',
                          'Consulta movimientos',
                          Icons.history,
                          AppColors.info,
                          '/inventory-history',
                        ),
                        _buildActionCard(
                          context,
                          'Ambiente',
                          'Vista general del ambiente',
                          Icons.location_on,
                          AppColors.success,
                          _environment != null
                              ? '/environment-overview'
                              : '/qr-scan',
                          extra: _environment != null
                              ? {
                                  'environmentId': _environment!['id'],
                                  'environmentName': _environment!['name'],
                                }
                              : null,
                        ),
                        _buildActionCard(
                          context,
                          'Cronograma',
                          'Horarios de capacitación',
                          Icons.schedule,
                          AppColors.primary,
                          '/training-schedule',
                        ),
                        _buildNotificationActionCard(context),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Notificaciones Recientes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_unreadNotificationsCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _unreadNotificationsCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_recentNotifications.isNotEmpty) ...[
                              ..._recentNotifications.map((notification) => 
                                _buildNotificationItem(
                                  notification['title'] ?? 'Sin título',
                                  notification['message'] ?? 'Sin mensaje',
                                  _getNotificationColor(notification['type'] ?? 'system'),
                                  !(notification['is_read'] ?? false),
                                ),
                              ),
                            ] else ...[
                              _buildNotificationItem(
                                'No hay notificaciones',
                                'Todas las notificaciones aparecerán aquí',
                                AppColors.grey500,
                                false,
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/notifications'),
                              child: const Text('Ver todas las notificaciones'),
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

  Widget _buildNotificationActionCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/notifications'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Icon(Icons.notifications, size: 40, color: AppColors.error),
                  if (_unreadNotificationsCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotificationsCount > 99 ? '99+' : _unreadNotificationsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _unreadNotificationsCount > 0 
                    ? '$_unreadNotificationsCount sin leer'
                    : 'Alertas y mensajes',
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

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'verification_pending':
        return AppColors.warning;
      case 'verification_update':
        return AppColors.secondary;
      case 'maintenance_update':
        return AppColors.info;
      case 'loan_approved':
        return AppColors.success;
      case 'loan_rejected':
      case 'loan_overdue':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Widget _buildNotificationItem(String title, String subtitle, Color statusColor, bool isUnread) {
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.secondary,
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
                  'Panel de Instructor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'instructor@sena.edu.co',
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
            onTap: () => context.go('/instructor-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Verificar Inventario'),
            onTap: () => context.push('/inventory-check'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Préstamos'),
            onTap: () => context.push('/loan-history'),
          ),
          ListTile(
            leading: const Icon(Icons.build_circle),
            title: const Text('Mantenimiento'),
            onTap: () => context.push('/maintenance-request'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Mi Ambiente'),
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
            leading: const Icon(Icons.schedule),
            title: const Text('Cronograma'),
            onTap: () => context.push('/training-schedule'),
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _unreadNotificationsCount > 9 ? '9+' : _unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Notificaciones'),
            onTap: () => context.push('/notifications'),
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
