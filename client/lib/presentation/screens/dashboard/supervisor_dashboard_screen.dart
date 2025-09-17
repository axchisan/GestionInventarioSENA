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

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  late final ApiService _apiService;
  Map<String, dynamic>? _environment;
  Map<String, dynamic>? _inventoryStats;
  List<Map<String, dynamic>> _recentNotifications = [];
  List<Map<String, dynamic>> _maintenanceRequests = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    try {
      if (user?.environmentId != null) {
        // Fetch environment info
        final environment = await _apiService.getSingle(
          '$environmentsEndpoint${user!.environmentId}',
        );

        // Fetch inventory items for detailed statistics
        final items = await _apiService.get(
          inventoryEndpoint,
          queryParams: {'environment_id': user.environmentId.toString()},
        );

        // Calculate detailed inventory statistics
        int totalItems = items.length;
        int totalQuantity = 0;
        int availableQuantity = 0;
        int damagedQuantity = 0;
        int missingQuantity = 0;
        int inUseQuantity = 0;
        int maintenanceQuantity = 0;

        // Count by status
        int availableItems = 0;
        int inUseItems = 0;
        int maintenanceItems = 0;
        int damagedItems = 0;
        int missingItems = 0;

        for (var item in items) {
          final quantity = (item['quantity'] as int? ?? 1);
          final quantityDamaged = (item['quantity_damaged'] as int? ?? 0);
          final quantityMissing = (item['quantity_missing'] as int? ?? 0);
          final status = item['status'] as String? ?? 'available';

          totalQuantity += quantity;
          damagedQuantity += quantityDamaged;
          missingQuantity += quantityMissing;

          // Calculate available quantity (total - damaged - missing)
          final itemAvailableQuantity =
              quantity - quantityDamaged - quantityMissing;
          availableQuantity += itemAvailableQuantity;

          // Count by status
          switch (status) {
            case 'available':
            case 'good':
              availableItems++;
              break;
            case 'in_use':
              inUseItems++;
              inUseQuantity += quantity;
              break;
            case 'maintenance':
              maintenanceItems++;
              maintenanceQuantity += quantity;
              break;
            case 'damaged':
              damagedItems++;
              break;
            case 'missing':
            case 'lost':
              missingItems++;
              break;
          }
        }

        // Fetch maintenance requests
        final maintenanceRequests = await _apiService.get(
          '/api/maintenance-requests/',
          queryParams: {'environment_id': user.environmentId.toString()},
        );

        setState(() {
          _environment = environment;
          _inventoryStats = {
            'total_items': totalItems,
            'total_quantity': totalQuantity,
            'available_quantity': availableQuantity,
            'damaged_quantity': damagedQuantity,
            'missing_quantity': missingQuantity,
            'in_use_quantity': inUseQuantity,
            'maintenance_quantity': maintenanceQuantity,
            'available_items': availableItems,
            'in_use_items': inUseItems,
            'maintenance_items': maintenanceItems,
            'damaged_items': damagedItems,
            'missing_items': missingItems,
          };
          _maintenanceRequests = List<Map<String, dynamic>>.from(
            maintenanceRequests,
          );
        });
      } else {
        // Para supervisor sin ambiente específico, fetch general stats
        final items = await _apiService.get(inventoryEndpoint);

        int totalItems = items.length;
        int totalQuantity = 0;
        int availableQuantity = 0;
        int damagedQuantity = 0;
        int missingQuantity = 0;

        for (var item in items) {
          final quantity = (item['quantity'] as int? ?? 1);
          final quantityDamaged = (item['quantity_damaged'] as int? ?? 0);
          final quantityMissing = (item['quantity_missing'] as int? ?? 0);

          totalQuantity += quantity;
          damagedQuantity += quantityDamaged;
          missingQuantity += quantityMissing;
          availableQuantity += (quantity - quantityDamaged - quantityMissing);
        }

        final maintenanceRequests = await _apiService.get(
          '/api/maintenance-requests/',
        );

        setState(() {
          _inventoryStats = {
            'total_items': totalItems,
            'total_quantity': totalQuantity,
            'available_quantity': availableQuantity,
            'damaged_quantity': damagedQuantity,
            'missing_quantity': missingQuantity,
            'available_items': items
                .where((item) => item['status'] == 'available')
                .length,
            'in_use_items': items
                .where((item) => item['status'] == 'in_use')
                .length,
            'maintenance_items': items
                .where((item) => item['status'] == 'maintenance')
                .length,
            'damaged_items': items
                .where((item) => item['status'] == 'damaged')
                .length,
            'missing_items': items
                .where((item) => ['missing', 'lost'].contains(item['status']))
                .length,
          };
          _maintenanceRequests = List<Map<String, dynamic>>.from(
            maintenanceRequests,
          );
        });
      }

      // Fetch notifications
      final notifications = await NotificationService.getNotifications();
      final unreadCount = await NotificationService.getUnreadCount();

      setState(() {
        _recentNotifications = notifications.take(3).toList();
        _unreadNotificationsCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
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
        title: 'Panel de Supervisor',
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
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
                                        ? 'Ambiente: ${_environment!['name']}'
                                        : 'Supervisión General',
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
                      'Estadísticas de Inventario',
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
                              'Items Totales',
                              _inventoryStats!['total_quantity'].toString(),
                              Icons.inventory,
                              AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Disponibles',
                              '${_inventoryStats!['available_quantity']}',
                              Icons.check_circle,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'En Uso',
                              '${_inventoryStats!['in_use_quantity'] ?? _inventoryStats!['in_use_items']}',
                              Icons.work,
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
                              '${_inventoryStats!['damaged_quantity']}',
                              Icons.broken_image,
                              AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Faltantes',
                              '${_inventoryStats!['missing_quantity']}',
                              Icons.error_outline,
                              AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Mantenimiento',
                              '${_inventoryStats!['maintenance_quantity'] ?? _inventoryStats!['maintenance_items']}',
                              Icons.build,
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Solicitudes',
                              _maintenanceRequests
                                  .where((req) => req['status'] == 'pending')
                                  .length
                                  .toString(),
                              Icons.notifications_active,
                              AppColors.warning,
                            ),
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
                                'Desglose Detallado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Cantidad Total de Unidades',
                                _inventoryStats!['total_quantity'].toString(),
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Unidades Disponibles',
                                _inventoryStats!['available_quantity']
                                    .toString(),
                                AppColors.success,
                              ),
                              _buildDetailRow(
                                'Unidades Dañadas',
                                _inventoryStats!['damaged_quantity'].toString(),
                                AppColors.warning,
                              ),
                              _buildDetailRow(
                                'Unidades Faltantes',
                                _inventoryStats!['missing_quantity'].toString(),
                                AppColors.error,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Items en Mantenimiento',
                                _inventoryStats!['maintenance_items']
                                    .toString(),
                              ),
                              _buildDetailRow(
                                'Items en Uso',
                                _inventoryStats!['in_use_items'].toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'No hay datos disponibles; vincula un ambiente',
                        style: TextStyle(color: AppColors.grey600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Panel de Control',
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
                          'Vincula ambiente para supervisar',
                          Icons.qr_code_scanner,
                          AppColors.primary,
                          '/qr-scan',
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
                          'Generar QR',
                          'Crea QR para items/ambientes',
                          Icons.qr_code,
                          AppColors.accent,
                          '/qr-generate',
                        ),
                        _buildActionCard(
                          context,
                          'Ambiente',
                          'Supervisa ambiente vinculado',
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
                          'Alertas de Inventario',
                          'Monitorea alertas',
                          Icons.warning,
                          AppColors.warning,
                          '/inventory-alerts',
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
                          'Generar Reportes',
                          'Crea reportes',
                          Icons.description,
                          AppColors.success,
                          '/report-generator',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
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
                              ..._recentNotifications.map(
                                (notification) => _buildNotificationItem(
                                  notification['title'] ?? 'Sin título',
                                  notification['message'] ?? 'Sin mensaje',
                                  _getNotificationColor(
                                    notification['type'] ?? 'system',
                                  ),
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

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.grey800,
            ),
          ),
        ],
      ),
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
                          _unreadNotificationsCount > 99
                              ? '99+'
                              : _unreadNotificationsCount.toString(),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _unreadNotificationsCount > 0
                    ? '$_unreadNotificationsCount sin leer'
                    : 'Revisa alertas',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.grey600),
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
        return AppColors.accent;
      case 'maintenance_update':
      case 'maintenance_request':
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

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    Color statusColor,
    bool isUnread,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
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
          Icon(Icons.chevron_right, color: AppColors.grey400, size: 16),
        ],
      ),
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
                style: const TextStyle(fontSize: 10, color: AppColors.grey600),
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
                Text(
                  user?.email ?? 'supervisor@sena.edu.co',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            leading: const Icon(Icons.qr_code),
            title: const Text('Generar QR'),
            onTap: () => context.push('/qr-generate'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Ambiente'),
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
            leading: const Icon(Icons.warning),
            title: const Text('Alertas de Inventario'),
            onTap: () => context.push('/inventory-alerts'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Estadísticas'),
            onTap: () => context.push('/statistics-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('generar Reportes'),
            onTap: () => context.push('/report-generator'),
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
                        _unreadNotificationsCount > 9
                            ? '9+'
                            : _unreadNotificationsCount.toString(),
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
