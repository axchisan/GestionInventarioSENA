import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../widgets/common/sena_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !(n['is_read'] ?? false)).length;
    
    return Scaffold(
      appBar: SenaAppBar(
        title: 'Notificaciones',
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Marcar todas',
                style: TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Contador de notificaciones
                if (unreadCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      'Tienes $unreadCount notificación${unreadCount > 1 ? 'es' : ''} sin leer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey600,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Sin Leer'),
                    Tab(text: 'Importantes'),
                  ],
                ),
                
                // Lista de notificaciones
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsList(_notifications),
                      _buildNotificationsList(
                        _notifications.where((n) => !(n['is_read'] ?? false)).toList(),
                      ),
                      _buildNotificationsList(
                        _notifications.where((n) => 
                          n['priority'] == 'high' || n['type']?.contains('overdue') == true
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'system';
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();
    final priority = notification['priority'] ?? 'medium';
    
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case 'loan_approved':
        typeColor = AppColors.success;
        typeIcon = Icons.check_circle;
        break;
      case 'loan_rejected':
      case 'loan_overdue':
        typeColor = AppColors.error;
        typeIcon = Icons.error;
        break;
      case 'loan_pending':
        typeColor = AppColors.warning;
        typeIcon = Icons.hourglass_empty;
        break;
      case 'loan_active':
        typeColor = AppColors.primary;
        typeIcon = Icons.play_circle;
        break;
      case 'loan_returned':
        typeColor = AppColors.success;
        typeIcon = Icons.assignment_return;
        break;
      case 'check_reminder':
      case 'verification_pending':
        typeColor = AppColors.warning;
        typeIcon = Icons.schedule;
        break;
      case 'maintenance_update':
        typeColor = AppColors.info;
        typeIcon = Icons.build;
        break;
      case 'verification_update':
        typeColor = AppColors.primary;
        typeIcon = Icons.inventory;
        break;
      case 'alert':
        typeColor = AppColors.error;
        typeIcon = Icons.warning;
        break;
      case 'system':
      default:
        typeColor = AppColors.info;
        typeIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : AppColors.primary.withOpacity(0.05),
      elevation: priority == 'high' ? 4 : 1,
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: priority == 'high' 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.5), width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono de tipo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Sin título',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (priority == 'high')
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.priority_high,
                                color: AppColors.warning,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? 'Sin mensaje',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                          const Spacer(),
                          _buildTypeChip(type),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Menú de opciones
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, notification),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: isRead ? 'unread' : 'read',
                      child: Row(
                        children: [
                          Icon(
                            isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(isRead ? 'Marcar como no leída' : 'Marcar como leída'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: AppColors.grey500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;
    Color color;
    
    switch (type) {
      case 'loan_approved':
        label = 'Préstamo Aprobado';
        color = AppColors.success;
        break;
      case 'loan_rejected':
        label = 'Préstamo Rechazado';
        color = AppColors.error;
        break;
      case 'loan_overdue':
        label = 'Préstamo Vencido';
        color = AppColors.error;
        break;
      case 'loan_pending':
        label = 'Préstamo Pendiente';
        color = AppColors.warning;
        break;
      case 'loan_active':
        label = 'Préstamo Activo';
        color = AppColors.primary;
        break;
      case 'loan_returned':
        label = 'Préstamo Devuelto';
        color = AppColors.success;
        break;
      case 'check_reminder':
        label = 'Recordatorio';
        color = AppColors.warning;
        break;
      case 'maintenance_update':
        label = 'Mantenimiento';
        color = AppColors.info;
        break;
      case 'verification_pending':
        label = 'Verificación Pendiente';
        color = AppColors.warning;
        break;
      case 'verification_update':
        label = 'Verificación';
        color = AppColors.primary;
        break;
      case 'alert':
        label = 'Alerta';
        color = AppColors.error;
        break;
      case 'system':
        label = 'Sistema';
        color = AppColors.secondary;
        break;
      default:
        label = 'General';
        color = AppColors.grey500;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    if (success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications.where((n) => !(n['is_read'] ?? false));
    
    for (final notification in unreadNotifications) {
      await NotificationService.markAsRead(notification['id']);
    }
    
    setState(() {
      for (var notification in _notifications) {
        notification['is_read'] = true;
      }
    });
  }

  void _handleMenuAction(String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'read':
        _markAsRead(notification['id']);
        break;
      case 'unread':
        // Para marcar como no leída, necesitaríamos un endpoint adicional
        setState(() {
          notification['is_read'] = false;
        });
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
