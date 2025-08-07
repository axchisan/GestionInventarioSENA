import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Préstamo Aprobado',
      'message': 'Tu solicitud de préstamo para Laptop Dell ha sido aprobada',
      'type': 'success',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'read': false,
      'category': 'loan',
    },
    {
      'id': '2',
      'title': 'Recordatorio de Devolución',
      'message': 'El préstamo del Proyector Epson vence mañana',
      'type': 'warning',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
      'category': 'reminder',
    },
    {
      'id': '3',
      'title': 'Mantenimiento Completado',
      'message': 'El mantenimiento del Taladro Industrial ha sido completado',
      'type': 'info',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'read': true,
      'category': 'maintenance',
    },
    {
      'id': '4',
      'title': 'Préstamo Vencido',
      'message': 'El préstamo de la Cámara Canon está vencido desde hace 2 días',
      'type': 'error',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'read': false,
      'category': 'overdue',
    },
    {
      'id': '5',
      'title': 'Nueva Actualización',
      'message': 'Sistema actualizado a la versión 2.1.0 con nuevas funcionalidades',
      'type': 'info',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
      'category': 'system',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;
    
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
        ],
      ),
      body: Column(
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
                  _notifications.where((n) => !n['read']).toList(),
                ),
                _buildNotificationsList(
                  _notifications.where((n) => 
                    n['type'] == 'error' || n['type'] == 'warning'
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

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;
    final type = notification['type'] as String;
    final timestamp = notification['timestamp'] as DateTime;
    
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case 'success':
        typeColor = AppColors.success;
        typeIcon = Icons.check_circle;
        break;
      case 'warning':
        typeColor = AppColors.warning;
        typeIcon = Icons.warning;
        break;
      case 'error':
        typeColor = AppColors.error;
        typeIcon = Icons.error;
        break;
      case 'info':
      default:
        typeColor = AppColors.info;
        typeIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(12),
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
                            notification['title'],
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
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
                          _formatTimestamp(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        _buildCategoryChip(notification['category']),
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: AppColors.error)),
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
    );
  }

  Widget _buildCategoryChip(String category) {
    String label;
    Color color;
    
    switch (category) {
      case 'loan':
        label = 'Préstamo';
        color = AppColors.primary;
        break;
      case 'reminder':
        label = 'Recordatorio';
        color = AppColors.warning;
        break;
      case 'maintenance':
        label = 'Mantenimiento';
        color = AppColors.info;
        break;
      case 'overdue':
        label = 'Vencido';
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

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  void _handleMenuAction(String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'read':
        _markAsRead(notification['id']);
        break;
      case 'unread':
        setState(() {
          notification['read'] = false;
        });
        break;
      case 'delete':
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notification['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación eliminada'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
