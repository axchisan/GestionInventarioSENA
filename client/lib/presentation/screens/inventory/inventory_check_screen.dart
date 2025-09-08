import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../maintenance/maintenance_request_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../widgets/common/notification_badge.dart';

class InventoryCheckScreen extends StatefulWidget {
  const InventoryCheckScreen({super.key});

  @override
  State<InventoryCheckScreen> createState() => _InventoryCheckScreenState();
}

class _InventoryCheckScreenState extends State<InventoryCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cleaningNotesController = TextEditingController();
  late final ApiService _apiService;
  String _selectedCategory = 'Todos';
  String _selectedStatus = 'Todos';
  String? _selectedScheduleId;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSchedule;
  Map<String, dynamic>? _currentScheduleCheck;
  List<dynamic> _scheduleStats = [];
  bool _showScheduleDetails = false;
  List<dynamic> _items = [];
  List<dynamic> _schedules = [];
  List<dynamic> _checks = [];
  List<dynamic> _pendingChecks = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasCheckedToday = false;
  final DateFormat _colombianTimeFormat = DateFormat('hh:mm a');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final Map<String, String> _categoryTranslations = {
    'computer': 'Computador',
    'projector': 'Proyector',
    'keyboard': 'Teclado',
    'mouse': 'Ratón',
    'tv': 'Televisor',
    'camera': 'Cámara',
    'microphone': 'Micrófono',
    'tablet': 'Tableta',
    'other': 'Otro',
  };

  final Map<String, String> _statusTranslations = {
    'available': 'Disponible',
    'in_use': 'En uso',
    'maintenance': 'En mantenimiento',
    'damaged': 'Dañado',
    'lost': 'Perdido',
    'good': 'Bueno',
    'missing': 'Faltante',
    'pending': 'Pendiente',
    'instructor_review': 'Revisión Instructor',
    'supervisor_review': 'Revisión Supervisor',
    'complete': 'Completo',
    'issues': 'Problemas',
    'incomplete': 'Incompleto',
  };

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.environmentId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vincula un ambiente para verificar el inventario'),
        ),
      );
      return;
    }
    try {
      final items = await _apiService.get(
        inventoryEndpoint,
        queryParams: {'environment_id': user!.environmentId.toString()},
      );
      final schedules = await _apiService.get(
        '/api/schedules/',
        queryParams: {'environment_id': user.environmentId.toString()},
      );
      final checks = await _apiService.get(
        inventoryChecksEndpoint,
        queryParams: {
          'environment_id': user.environmentId.toString(),
          'date': _dateFormat.format(_selectedDate),
        },
      );
      final notifications = await _apiService.get(
        '/api/notifications/',
      );
      
      List<dynamic> filteredChecks = checks;
      if (_selectedScheduleId != null) {
        filteredChecks = checks.where((check) => 
          check['schedule_id'] == _selectedScheduleId).toList();
      }
      
      final pendingChecks = filteredChecks.where((check) => 
        ['pending', 'instructor_review', 'supervisor_review'].contains(check['status'])).toList();
      
      bool hasCheckedScheduleToday = false;
      if (_selectedScheduleId != null) {
        hasCheckedScheduleToday = filteredChecks.any((check) => 
          check['check_date'] == _dateFormat.format(_selectedDate) &&
          check['schedule_id'] == _selectedScheduleId);
      }
      
      await _fetchScheduleStats();
      
      setState(() {
        _items = items;
        _schedules = schedules;
        _checks = filteredChecks;
        _pendingChecks = pendingChecks;
        _notifications = notifications;
        _hasCheckedToday = hasCheckedScheduleToday;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchScheduleStats() async {
    if (_selectedScheduleId == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      final stats = await _apiService.get(
        '/api/inventory-checks/schedule-stats',
        queryParams: {
          'environment_id': user!.environmentId.toString(),
          'schedule_id': _selectedScheduleId!,
          'date': _dateFormat.format(_selectedDate),
        },
      );
      
      setState(() {
        _scheduleStats = stats;
      });
    } catch (e) {
      print('Error al cargar estadísticas del horario: $e');
    }
  }

  Future<void> _fetchScheduleCheck() async {
    if (_selectedScheduleId == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      final checkData = await _apiService.get(
        '/api/inventory-checks/by-schedule',
        queryParams: {
          'environment_id': user!.environmentId.toString(),
          'schedule_id': _selectedScheduleId!,
          'date': _dateFormat.format(_selectedDate),
        },
      );
      
      setState(() {
        _currentScheduleCheck = checkData.isNotEmpty ? checkData.first : null;
      });
    } catch (e) {
      print('Error al cargar verificación del horario: $e');
    }
  }

  List<dynamic> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item['id'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todos' || (_categoryTranslations[item['category']] ?? item['category']) == _selectedCategory;
      final matchesStatus = _selectedStatus == 'Todos' || (_statusTranslations[item['status']] ?? item['status']) == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  String _formatColombianTime(String timeStr) {
    try {
      final dateTime = DateFormat('HH:mm').parse(timeStr);
      return _colombianTimeFormat.format(dateTime);
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentUser?.role ?? '';
    final environmentId = authProvider.currentUser?.environmentId ?? '';

    return Scaffold(
      appBar: SenaAppBar(
        title: 'Verificación de Inventario',
        actions: [
          // Botón de notificaciones con badge
          NotificationBadge(
            onTap: () => _showNotificationsModal(),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationsModal(),
            ),
          ),
          
          // Botón de verificaciones pendientes
          if (_pendingChecks.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.pending_actions),
                  onPressed: () => _showPendingChecksModal(),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _pendingChecks.length.toString(),
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
          
          // Botón de historial
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryModal(),
          ),
          
          // Botón de solicitud de mantenimiento
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () => _navigateToMaintenanceRequest(environmentId),
            tooltip: 'Solicitar Mantenimiento',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _selectDate(),
                                icon: const Icon(Icons.edit_calendar),
                                label: const Text('Cambiar'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: [
                                  'Todos',
                                  ..._categoryTranslations.values.toList(),
                                ].map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: [
                                  'Todos',
                                  ..._statusTranslations.values.toList(),
                                ].map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (role == 'student' || role == 'instructor' || role == 'supervisor') ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedScheduleId,
                                  decoration: InputDecoration(
                                    labelText: 'Turno/Horario',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _schedules.map((schedule) {
                                    return DropdownMenuItem(
                                      value: schedule['id'].toString(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${schedule['program']} - ${schedule['ficha']}'),
                                          Text(
                                            '${_formatColombianTime(schedule['start_time'])} - ${_formatColombianTime(schedule['end_time'])}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedScheduleId = value;
                                      _selectedSchedule = _schedules.firstWhere(
                                        (s) => s['id'].toString() == value,
                                        orElse: () => null,
                                      );
                                    });
                                    if (value != null) {
                                      _fetchScheduleCheck();
                                      _fetchData();
                                    }
                                  },
                                ),
                                if (_selectedSchedule != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildScheduleInfo(
                                            Icons.people,
                                            'Estudiantes',
                                            '${_selectedSchedule!['student_count']}',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildScheduleInfo(
                                            Icons.access_time,
                                            'Duración',
                                            _calculateDuration(_selectedSchedule!['start_time'], _selectedSchedule!['end_time']),
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildScheduleInfo(
                                            Icons.assignment_turned_in,
                                            'Estado',
                                            _hasCheckedToday ? 'Verificado' : 'Pendiente',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (_hasCheckedToday && _selectedScheduleId != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Inventario ya verificado para este horario hoy. Puedes ver detalles o actualizar individualmente.',
                                    style: TextStyle(color: AppColors.success),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showScheduleDetailsModal(),
                                  child: const Text('Ver Detalles'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final role = authProvider.currentUser?.role ?? '';
                        return _buildItemCard(item, role);
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (role == 'supervisor' || role == 'admin') ...[
            FloatingActionButton(
              heroTag: 'add',
              onPressed: () {
                context.push('/add-inventory-item', extra: {'environmentId': environmentId});
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
          if ((role == 'student' || role == 'instructor' || role == 'supervisor') && 
              !_hasCheckedToday && _selectedScheduleId != null) ...[
            FloatingActionButton(
              heroTag: 'check',
              onPressed: _showCheckDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
          // Botón flotante para mantenimiento general
          FloatingActionButton(
            heroTag: 'maintenance',
            onPressed: () => _navigateToMaintenanceRequest(environmentId),
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.build, color: Colors.white),
            tooltip: 'Solicitud de Mantenimiento',
          ),
        ],
      ),
    );
  }

  void _navigateToMaintenanceRequest(String environmentId, {String? itemId, String? itemName}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceRequestScreen(
          environmentId: environmentId,
          preselectedItemId: itemId,
          preselectedItemName: itemName,
        ),
      ),
    );
    
    if (result == true) {
      // Actualizar datos después de crear solicitud de mantenimiento
      _fetchData();
      
      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de mantenimiento enviada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: NotificationService.getNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  
                  final notifications = snapshot.data ?? [];
                  
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 48, color: AppColors.grey400),
                          SizedBox(height: 16),
                          Text('No hay notificaciones'),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'system';
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();
    
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case 'verification_pending':
        typeColor = AppColors.warning;
        typeIcon = Icons.schedule;
        break;
      case 'verification_update':
        typeColor = AppColors.primary;
        typeIcon = Icons.inventory;
        break;
      case 'maintenance_update':
        typeColor = AppColors.info;
        typeIcon = Icons.build;
        break;
      default:
        typeColor = AppColors.info;
        typeIcon = Icons.info;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(
          notification['title'] ?? 'Sin título',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? 'Sin mensaje'),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          if (!isRead) {
            await NotificationService.markAsRead(notification['id']);
          }
        },
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

  void _showScheduleDetailsModal() {
    if (_selectedSchedule == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedSchedule!['program']} - ${_selectedSchedule!['ficha']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatColombianTime(_selectedSchedule!['start_time'])} - ${_formatColombianTime(_selectedSchedule!['end_time'])}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del horario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Horario',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildScheduleInfo(
                                    Icons.people,
                                    'Estudiantes',
                                    '${_selectedSchedule!['student_count']}',
                                  ),
                                ),
                                Expanded(
                                  child: _buildScheduleInfo(
                                    Icons.calendar_today,
                                    'Fecha',
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildScheduleInfo(
                                    Icons.access_time,
                                    'Duración',
                                    _calculateDuration(_selectedSchedule!['start_time'], _selectedSchedule!['end_time']),
                                  ),
                                ),
                                Expanded(
                                  child: _buildScheduleInfo(
                                    Icons.topic,
                                    'Tema',
                                    _selectedSchedule!['topic'] ?? 'No especificado',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Estado de verificación
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estado de Verificación',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (_currentScheduleCheck != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: AppColors.success),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Verificación Completada',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'Total Items',
                                            '${_currentScheduleCheck!['total_items'] ?? 0}',
                                            AppColors.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStatItem(
                                            'Buenos',
                                            '${_currentScheduleCheck!['items_good'] ?? 0}',
                                            AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'Dañados',
                                            '${_currentScheduleCheck!['items_damaged'] ?? 0}',
                                            AppColors.warning,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStatItem(
                                            'Faltantes',
                                            '${_currentScheduleCheck!['items_missing'] ?? 0}',
                                            AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warning),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.pending, color: AppColors.warning),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Verificación Pendiente',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasCheckedToday = false;
        _currentScheduleCheck = null;
      });
      _fetchData();
    }
  }

  Widget _buildScheduleInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _calculateDuration(String startTime, String endTime) {
    try {
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);
      final duration = end.difference(start);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showPendingChecksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Verificaciones Pendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _pendingChecks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay verificaciones pendientes', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingChecks.length,
                      itemBuilder: (context, index) {
                        final check = _pendingChecks[index];
                        final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getStatusColor(check['status']),
                              child: const Icon(Icons.assignment, color: Colors.white),
                            ),
                            title: Text('Verificación #${check['id'].toString().substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                                Text('Fecha: ${check['check_date']}'),
                                if (check['check_time'] != null)
                                  Text('Hora: ${_formatColombianTime(check['check_time'])}'),
                              ],
                            ),
                            trailing: role == 'instructor' && check['status'] == 'instructor_review'
                                ? ElevatedButton(
                                    onPressed: () => _confirmInstructorCheck(check),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                    child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                                  )
                                : role == 'supervisor' && check['status'] == 'supervisor_review'
                                    ? ElevatedButton(
                                        onPressed: () => _reviewSupervisorCheck(check),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                        child: const Text('Revisar', style: TextStyle(color: Colors.white)),
                                      )
                                    : null,
                            onTap: () => _showCheckDetails(check),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey600,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Historial de Verificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _checks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay historial disponible', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _checks.length,
                      itemBuilder: (context, index) {
                        final check = _checks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getStatusColor(check['status']),
                              child: const Icon(Icons.assignment_turned_in, color: Colors.white),
                            ),
                            title: Text('Verificación #${check['id'].toString().substring(0, 8)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                                Text('Fecha: ${check['check_date']}'),
                                if (check['check_time'] != null)
                                  Text('Hora: ${_formatColombianTime(check['check_time'])}'),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () => _showCheckDetails(check),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String role) {
    Color statusColor = getStatusColor(item['status']);
    final isGroup = item['item_type'] == 'group';
    final itemName = item['name'] ?? 'Sin nombre';
    final itemCode = item['code'] ?? item['id'] ?? 'Sin código';
    final checkData = _getItemCheckData(item['id']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(item['category'] ?? 'other'),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGroup ? 'Grupo: Encontrados ${item['quantity'] - (item['quantity_damaged'] ?? 0) - (item['quantity_missing'] ?? 0)}, Dañados ${item['quantity_damaged'] ?? 0}, Faltantes ${item['quantity_missing'] ?? 0}' : 'Código: $itemCode',
                          style: const TextStyle(
                            color: AppColors.grey600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.build, color: AppColors.secondary),
                    onPressed: () => _navigateToMaintenanceRequest(
                      Provider.of<AuthProvider>(context, listen: false).currentUser?.environmentId ?? '',
                      itemId: item['id'],
                      itemName: itemName,
                    ),
                    tooltip: 'Solicitar mantenimiento para este item',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _statusTranslations[item['status']] ?? item['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.category,
                      'Categoría',
                      _categoryTranslations[item['category']] ?? item['category'],
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on,
                      'Ubicación',
                      item['environment_id'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Última Verificación',
                      item['updated_at'] ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.star,
                      'Condición',
                      _statusTranslations[item['status']] ?? item['status'],
                    ),
                  ),
                ],
              ),
              if (checkData != null) ...[
                const SizedBox(height: 12),
                _buildCheckDataSection(checkData, item),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateItemStatus(item),
                      icon: const Icon(Icons.edit),
                      label: const Text('Actualizar Estado'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  if (role == 'supervisor' || role == 'admin') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editItemDialog(item),
                        icon: const Icon(Icons.edit_document),
                        label: const Text('Editar Item'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteItem(item),
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateItemStatus(Map<String, dynamic> item) {
    final isGroup = item['item_type'] == 'group';
    int quantityExpected = item['quantity'] ?? 1;
    int quantityFound = quantityExpected;
    int quantityDamaged = 0;
    int quantityMissing = 0;
    String notes = '';
    String newStatus = 'good';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Actualizar ${item['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado General',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: newStatus,
                        items: [
                          DropdownMenuItem(
                            value: 'good',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Text(_statusTranslations['good'] ?? 'Bueno'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'damaged',
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: AppColors.warning, size: 20),
                                const SizedBox(width: 8),
                                Text(_statusTranslations['damaged'] ?? 'Dañado'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'missing',
                            child: Row(
                              children: [
                                Icon(Icons.error, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Text(_statusTranslations['missing'] ?? 'Faltante'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            newStatus = value!;
                            if (newStatus == 'good') {
                              quantityFound = quantityExpected;
                              quantityDamaged = 0;
                              quantityMissing = 0;
                            } else if (newStatus == 'damaged') {
                              quantityFound = 0;
                              quantityDamaged = quantityExpected;
                              quantityMissing = 0;
                            } else if (newStatus == 'missing') {
                              quantityFound = 0;
                              quantityDamaged = 0;
                              quantityMissing = quantityExpected;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isGroup) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Gestión de Cantidades',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Total esperado: $quantityExpected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Encontrados
                        _buildQuantityControl(
                          'Encontrados',
                          quantityFound,
                          AppColors.success,
                          Icons.check_circle,
                          (increment) {
                            setDialogState(() {
                              if (increment && quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                quantityFound++;
                              } else if (!increment && quantityFound > 0) {
                                quantityFound--;
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                  // Priorizar dañados sobre faltantes
                                  if (newStatus == 'damaged' || quantityDamaged > 0) {
                                    quantityDamaged++;
                                  } else {
                                    quantityMissing++;
                                  }
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Dañados
                        _buildQuantityControl(
                          'Dañados',
                          quantityDamaged,
                          AppColors.warning,
                          Icons.warning,
                          (increment) {
                            setDialogState(() {
                              if (increment && quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                quantityDamaged++;
                              } else if (!increment && quantityDamaged > 0) {
                                quantityDamaged--;
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                  quantityFound++;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Faltantes
                        _buildQuantityControl(
                          'Faltantes',
                          quantityMissing,
                          AppColors.error,
                          Icons.error,
                          (increment) {
                            setDialogState(() {
                              if (increment && quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                quantityMissing++;
                              } else if (!increment && quantityMissing > 0) {
                                quantityMissing--;
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) {
                                  quantityFound++;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getQuantityStatusColor(quantityFound, quantityDamaged, quantityMissing, quantityExpected).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getQuantityStatusColor(quantityFound, quantityDamaged, quantityMissing, quantityExpected),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getQuantityStatusIcon(quantityFound, quantityDamaged, quantityMissing, quantityExpected),
                                color: _getQuantityStatusColor(quantityFound, quantityDamaged, quantityMissing, quantityExpected),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Total reportado: ${quantityFound + quantityDamaged + quantityMissing}/$quantityExpected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getQuantityStatusColor(quantityFound, quantityDamaged, quantityMissing, quantityExpected),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Notas adicionales',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.note_add),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    notes = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isGroup) {
                  final totalReported = quantityFound + quantityDamaged + quantityMissing;
                  if (totalReported != quantityExpected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Las cantidades deben sumar $quantityExpected. Actual: $totalReported'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                }
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  // Crea InventoryCheckItem
                  await _apiService.post(
                    '/api/inventory-check-items/',
                    {
                      'item_id': item['id'],
                      'status': newStatus,
                      'quantity_expected': quantityExpected,
                      'quantity_found': quantityFound,
                      'quantity_damaged': quantityDamaged,
                      'quantity_missing': quantityMissing,
                      'notes': notes,
                      'environment_id': authProvider.currentUser!.environmentId,
                    },
                  );
                  String updatedStatus = _determineItemStatus(quantityFound, quantityDamaged, quantityMissing);
                  await _apiService.put(
                    '$inventoryEndpoint${item['id']}',
                    {
                      'quantity': quantityFound + quantityDamaged,
                      'status': updatedStatus,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item actualizado: ${_statusTranslations[newStatus] ?? newStatus}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(String label, int quantity, Color color, IconData icon, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: quantity > 0 ? () => onChanged(false) : null,
                  color: color,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onChanged(true),
                  color: color,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuantityStatusColor(int found, int damaged, int missing, int expected) {
    final total = found + damaged + missing;
    if (total == expected) {
      if (missing > 0) return AppColors.error;
      if (damaged > 0) return AppColors.warning;
      return AppColors.success;
    }
    return AppColors.grey500;
  }

  IconData _getQuantityStatusIcon(int found, int damaged, int missing, int expected) {
    final total = found + damaged + missing;
    if (total == expected) {
      if (missing > 0) return Icons.error;
      if (damaged > 0) return Icons.warning;
      return Icons.check_circle;
    }
    return Icons.help;
  }

  String _determineItemStatus(int found, int damaged, int missing) {
    if (missing > 0) return 'lost';
    if (damaged > 0 && found == 0) return 'damaged';
    if (damaged > 0 && found > 0) return 'maintenance';
    return 'available';
  }

  void _markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.put('/api/notifications/$notificationId/read', {});
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar notificación: $e')),
      );
    }
  }

  void _confirmInstructorCheck(Map<String, dynamic> check) async {
    try {
      await _apiService.put('/api/inventory-checks/${check['id']}/confirm', {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificación confirmada por instructor')),
      );
      _fetchData();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _reviewSupervisorCheck(Map<String, dynamic> check) async {
    // Implementar lógica de revisión del supervisor
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisión de Supervisor'),
        content: const Text('¿Aprobar esta verificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.put('/api/inventory-checks/${check['id']}/supervisor-approve', {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verificación aprobada por supervisor')),
                );
                _fetchData();
                Navigator.pop(context);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showCheckDetails(Map<String, dynamic> check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verificación #${check['id'].toString().substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
              Text('Fecha: ${check['check_date']}'),
              if (check['check_time'] != null)
                Text('Hora: ${_formatColombianTime(check['check_time'])}'),
              Text('Total Items: ${check['total_items'] ?? 0}'),
              Text('Items Buenos: ${check['items_good'] ?? 0}'),
              Text('Items Dañados: ${check['items_damaged'] ?? 0}'),
              Text('Items Faltantes: ${check['items_missing'] ?? 0}'),
              Text('Limpio: ${check['is_clean'] == true ? 'Sí' : 'No'}'),
              Text('Organizado: ${check['is_organized'] == true ? 'Sí' : 'No'}'),
              if (check['cleaning_notes'] != null)
                Text('Notas de Limpieza: ${check['cleaning_notes']}'),
              if (check['comments'] != null)
                Text('Comentarios: ${check['comments']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${item['id']}'),
              Text('Categoría: ${_categoryTranslations[item['category']] ?? item['category']}'),
              Text('Estado: ${_statusTranslations[item['status']] ?? item['status']}'),
              Text('Ubicación: ${item['environment_id'] ?? 'N/A'}'),
              Text('Descripción: ${item['description'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editItemDialog(Map<String, dynamic> item) {
    // Implementar lógica de edición del item
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: const Text('Implementar lógica de edición aquí'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) async {
    // Implementar lógica de eliminación del item
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Item'),
        content: const Text('¿Seguro que quieres eliminar este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.delete('$inventoryEndpoint${item['id']}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item eliminado')),
                );
                _fetchData();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCheckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificación de Inventario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿El ambiente está limpio y organizado?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                        onPressed: () {
                          Navigator.pop(context);
                          _saveCheck(true, true);
                        },
                      ),
                      const Text('Sí'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 48, color: AppColors.error),
                        onPressed: () {
                          Navigator.pop(context);
                          _saveCheck(false, false);
                        },
                      ),
                      const Text('No'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cleaningNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notas de limpieza (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveCheck(true, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showReportDamageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Daño'),
        content: const Text('Implementar lógica de reporte de daño aquí'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCheck(bool isClean, bool isOrganized) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    try {
      final totalItems = _items.length;
      final itemsGood = _items.where((item) => item['status'] == 'good').length;
      final itemsDamaged = _items.where((item) => item['status'] == 'damaged').length;
      final itemsMissing = _items.where((item) => item['status'] == 'missing').length;

      final checkData = {
        'environment_id': user.environmentId,
        'check_date': DateTime.now().toIso8601String().split('T')[0],
        'check_time': DateFormat('HH:mm').format(DateTime.now()),
        'total_items': totalItems,
        'items_good': itemsGood,
        'items_damaged': itemsDamaged,
        'items_missing': itemsMissing,
        'is_clean': isClean,
        'is_organized': isOrganized,
        'cleaning_notes': _cleaningNotesController.text,
        'schedule_id': _selectedScheduleId,
      };

      await _apiService.post(inventoryChecksEndpoint, checkData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificación guardada')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar verificación: $e')),
      );
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckDataSection(Map<String, dynamic> checkData, Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Última Verificación:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fecha: ${checkData['check_date']}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Estado: ${_statusTranslations[checkData['status']] ?? checkData['status']}',
          style: const TextStyle(fontSize: 12),
        ),
        if (checkData['notes'] != null && checkData['notes'].isNotEmpty)
          Text(
            'Notas: ${checkData['notes']}',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  Map<String, dynamic>? _getItemCheckData(String itemId) {
    // Buscar la información de verificación del item en la lista de verificaciones
    try {
      return _checks.firstWhere((check) => check['item_id'] == itemId);
    } catch (e) {
      return null;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'computer':
        return Icons.computer;
      case 'projector':
        return Icons.tv;
      case 'keyboard':
        return Icons.keyboard;
      case 'mouse':
        return Icons.mouse;
      default:
        return Icons.devices_other;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'available':
      case 'good':
      case 'complete':
        return AppColors.success;
      case 'in_use':
        return AppColors.info;
      case 'maintenance':
      case 'instructor_review':
      case 'supervisor_review':
        return AppColors.warning;
      case 'damaged':
      case 'missing':
      case 'lost':
      case 'issues':
      case 'incomplete':
        return AppColors.error;
      case 'pending':
        return AppColors.grey500;
      default:
        return AppColors.grey500;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cleaningNotesController.dispose();
    _apiService.dispose();
    super.dispose();
  }
}