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
  List<dynamic> _items = [];
  List<dynamic> _schedules = [];
  List<dynamic> _checks = [];
  List<dynamic> _pendingChecks = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasCheckedToday = false;
  final DateFormat _colombianTimeFormat = DateFormat('hh:mm a');

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
      
      Map<String, String> checkParams = {'environment_id': user.environmentId.toString()};
      if (_selectedScheduleId != null) {
        checkParams['schedule_id'] = _selectedScheduleId!;
      }
      
      final checks = await _apiService.get(
        inventoryChecksEndpoint,
        queryParams: checkParams,
      );
      
      final notifications = await _apiService.get(
        '/api/notifications/',
      );
      
      final pendingChecks = checks.where((check) => ['pending', 'instructor_review', 'supervisor_review'].contains(check['status'] ?? '')).toList();
      
      bool hasCheckedToday = false;
      if (_selectedScheduleId != null) {
        hasCheckedToday = checks.any((check) => 
          check['schedule_id'] == _selectedScheduleId &&
          check['check_date'] == DateTime.now().toIso8601String().split('T')[0]
        );
      } else {
        hasCheckedToday = checks.any((check) => 
          check['check_date'] == DateTime.now().toIso8601String().split('T')[0]
        );
      }
      
      setState(() {
        _items = items;
        _schedules = schedules;
        _checks = checks;
        _pendingChecks = pendingChecks;
        _notifications = notifications;
        _hasCheckedToday = hasCheckedToday;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
      setState(() {
        _isLoading = false;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Inventario'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (_notifications.any((n) => !n['is_read']))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_notifications.where((n) => !n['is_read']).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showNotificationsModal(),
              tooltip: 'Notificaciones',
            ),
          if (role == 'instructor' || role == 'supervisor')
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.pending_actions),
                  if (_pendingChecks.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_pendingChecks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showPendingChecksModal(),
              tooltip: 'Verificaciones Pendientes',
            ),
          if (_checks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showHistoryModal(),
              tooltip: 'Historial',
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
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filtros de Búsqueda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                          DropdownButtonFormField<String>(
                            value: _selectedScheduleId,
                            decoration: InputDecoration(
                              labelText: 'Turno/Horario',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos los horarios'),
                              ),
                              ..._schedules.map((schedule) {
                                return DropdownMenuItem(
                                  value: schedule['id'].toString(),
                                  child: Text('${schedule['program']} - ${_formatColombianTime(schedule['start_time'])} - ${_formatColombianTime(schedule['end_time'])}'),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedScheduleId = value;
                              });
                              _fetchData();
                            },
                          ),
                        ],
                        if (_selectedScheduleId != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _hasCheckedToday ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hasCheckedToday ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasCheckedToday ? Icons.check_circle : Icons.schedule,
                                  color: _hasCheckedToday ? AppColors.success : AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hasCheckedToday 
                                      ? 'Inventario verificado hoy para este horario'
                                      : 'Pendiente verificación para este horario',
                                    style: TextStyle(
                                      color: _hasCheckedToday ? AppColors.success : AppColors.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron elementos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajusta los filtros para ver más elementos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return _buildItemCard(item, role);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButtons(role, authProvider),
    );
  }

  Widget _buildFloatingActionButtons(String role, AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (role == 'supervisor' || role == 'admin') ...[
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              context.push('/add-inventory-item', extra: {'environmentId': authProvider.currentUser?.environmentId});
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Agregar Item',
          ),
          const SizedBox(height: 16),
        ],
        if ((role == 'student' || role == 'instructor' || role == 'supervisor') && !_hasCheckedToday) ...[
          FloatingActionButton(
            heroTag: 'check',
            onPressed: _showCheckDialog,
            backgroundColor: AppColors.success,
            child: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Verificar Inventario',
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          heroTag: 'report',
          onPressed: _showReportDamageDialog,
          backgroundColor: AppColors.error,
          child: const Icon(Icons.report_problem, color: Colors.white),
          tooltip: 'Reportar Problema',
        ),
      ],
    );
  }

  void _showNotificationsModal() {
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
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              child: _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay notificaciones', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notif['is_read'] ? Colors.grey : AppColors.primary,
                              child: Icon(
                                notif['is_read'] ? Icons.check : Icons.notifications_active,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notif['title'],
                              style: TextStyle(
                                fontWeight: notif['is_read'] ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notif['message']),
                            trailing: notif['is_read'] 
                              ? null 
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
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
                color: Colors.orange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verificaciones Pendientes',
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
              child: _pendingChecks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('No hay verificaciones pendientes', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingChecks.length,
                      itemBuilder: (context, index) {
                        final check = _pendingChecks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getStatusColor(check['status']),
                              child: const Icon(Icons.pending, color: Colors.white),
                            ),
                            title: Text('Check ID: ${check['id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                                Text('Hora: ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
                              ],
                            ),
                            trailing: _buildVerificationActions(check, true),
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
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Historial de Verificaciones',
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
              child: _checks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay historial disponible', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                              child: Icon(
                                _getStatusIcon(check['status']),
                                color: Colors.white,
                              ),
                            ),
                            title: Text('Check ID: ${check['id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha: ${check['check_date']}'),
                                Text('Hora: ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
                                Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                                if (check['total_items'] != null)
                                  Text('Items: ${check['items_good'] ?? 0} buenos, ${check['items_damaged'] ?? 0} dañados, ${check['items_missing'] ?? 0} faltantes'),
                              ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'issues':
      case 'incomplete':
        return Icons.error;
      case 'instructor_review':
      case 'supervisor_review':
        return Icons.rate_review;
      default:
        return Icons.help;
    }
  }

  Widget? _buildVerificationActions(Map<String, dynamic> check, bool isPending) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUser?.role ?? '';
    
    if (!isPending) return null;
    
    if (role == 'instructor' && check['status'] == 'instructor_review') {
      return ElevatedButton(
        onPressed: () => _confirmInstructorCheck(check),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
        child: const Text('Confirmar'),
      );
    } else if (role == 'supervisor' && check['status'] == 'supervisor_review') {
      return ElevatedButton(
        onPressed: () => _reviewSupervisorCheck(check),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: const Text('Revisar'),
      );
    }
    return null;
  }

  Widget _buildItemCard(Map<String, dynamic> item, String role) {
    Color statusColor = getStatusColor(item['status']);
    final isGroup = item['item_type'] == 'group';
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGroup ? 'Grupo: Encontrados ${item['quantity'] - (item['quantity_damaged'] ?? 0) - (item['quantity_missing'] ?? 0)}, Dañados ${item['quantity_damaged'] ?? 0}, Faltantes ${item['quantity_missing'] ?? 0}' : 'ID: ${item['id']}',
                          style: const TextStyle(
                            color: AppColors.grey600,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
                      Icons.numbers,
                      'Cantidad',
                      '${item['quantity'] ?? 1}',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateItemStatus(item),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Actualizar Estado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (role == 'supervisor' || role == 'admin') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editItemDialog(item),
                        icon: const Icon(Icons.edit_document, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      tooltip: 'Eliminar',
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


  void _editItemDialog(Map<String, dynamic> item) {
    // Lógica de edición movida aquí desde EditInventoryItemScreen
    String name = item['name'] ?? '';
    String internalCode = item['internal_code'] ?? '';
    String category = item['category'] ?? 'other';
    int quantity = item['quantity'] ?? 1;
    String itemType = item['item_type'] ?? 'individual';
    String status = item['status'] ?? 'available';
    String serialNumber = item['serial_number'] ?? '';
    String brand = item['brand'] ?? '';
    String model = item['model'] ?? '';
    DateTime? purchaseDate = item['purchase_date'] != null ? DateTime.parse(item['purchase_date']) : null;
    DateTime? warrantyExpiry = item['warranty_expiry'] != null ? DateTime.parse(item['warranty_expiry']) : null;
    DateTime? lastMaintenance = item['last_maintenance'] != null ? DateTime.parse(item['last_maintenance']) : null;
    DateTime? nextMaintenance = item['next_maintenance'] != null ? DateTime.parse(item['next_maintenance']) : null;
    String imageUrl = item['image_url'] ?? '';
    String notes = item['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (value) => name = value,
                  controller: TextEditingController(text: name),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Código Interno'),
                  onChanged: (value) => internalCode = value,
                  controller: TextEditingController(text: internalCode),
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setDialogState(() => category = value!),
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => quantity = int.tryParse(value) ?? 1,
                  controller: TextEditingController(text: quantity.toString()),
                ),
                DropdownButtonFormField<String>(
                  value: itemType,
                  items: ['individual', 'group'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setDialogState(() => itemType = value!),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['available', 'in_use', 'maintenance', 'damaged', 'lost']
                      .map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Número de Serie (opcional)'),
                  onChanged: (value) => serialNumber = value,
                  controller: TextEditingController(text: serialNumber),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Marca (opcional)'),
                  onChanged: (value) => brand = value,
                  controller: TextEditingController(text: brand),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Modelo (opcional)'),
                  onChanged: (value) => model = value,
                  controller: TextEditingController(text: model),
                ),
                ListTile(
                  title: Text('Fecha de Compra: ${purchaseDate?.toString() ?? 'No seleccionada'}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: purchaseDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => purchaseDate = picked);
                  },
                ),
                ListTile(
                  title: Text('Vencimiento Garantía: ${warrantyExpiry?.toString() ?? 'No seleccionada'}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: warrantyExpiry ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => warrantyExpiry = picked);
                  },
                ),
                ListTile(
                  title: Text('Último Mantenimiento: ${lastMaintenance?.toString() ?? 'No seleccionada'}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: lastMaintenance ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => lastMaintenance = picked);
                  },
                ),
                ListTile(
                  title: Text('Próximo Mantenimiento: ${nextMaintenance?.toString() ?? 'No seleccionada'}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: nextMaintenance ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => nextMaintenance = picked);
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'URL Imagen (opcional)'),
                  onChanged: (value) => imageUrl = value,
                  controller: TextEditingController(text: imageUrl),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                  onChanged: (value) => notes = value,
                  controller: TextEditingController(text: notes),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.put(
                    '$inventoryEndpoint${item['id']}',
                    {
                      'name': name,
                      'internal_code': internalCode,
                      'category': category,
                      'quantity': quantity,
                      'item_type': itemType,
                      'status': status,
                      'serial_number': serialNumber.isEmpty ? null : serialNumber,
                      'brand': brand.isEmpty ? null : brand,
                      'model': model.isEmpty ? null : model,
                      'purchase_date': purchaseDate?.toIso8601String(),
                      'warranty_expiry': warrantyExpiry?.toIso8601String(),
                      'last_maintenance': lastMaintenance?.toIso8601String(),
                      'next_maintenance': nextMaintenance?.toIso8601String(),
                      'image_url': imageUrl.isEmpty ? null : imageUrl,
                      'notes': notes.isEmpty ? null : notes,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item actualizado')));
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.delete('$inventoryEndpoint${item['id']}');
                _fetchData();
                Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'good':
        return AppColors.success;
      case 'in_use':
        return AppColors.warning;
      case 'maintenance':
      case 'damaged':
        return AppColors.error;
      case 'lost':
      case 'missing':
        return AppColors.error;
      case 'pending':
        return AppColors.grey500;
      case 'complete':
        return AppColors.success;
      case 'issues':
      case 'incomplete':
        return AppColors.error;
      case 'instructor_review':
        return AppColors.warning;
      case 'supervisor_review':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.grey600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
              Text('Cantidad: ${item['quantity'] ?? 1} (Encontrados: ${item['quantity_found'] ?? 0}, Dañados: ${item['quantity_damaged'] ?? 0}, Faltantes: ${item['quantity_missing'] ?? 0})'),
              Text('Tipo: ${item['item_type'] == 'group' ? 'Grupo' : 'Individual'}'),
              Text('Número de Serie: ${item['serial_number'] ?? 'N/A'}'),
              Text('Marca: ${item['brand'] ?? 'N/A'}'),
              Text('Modelo: ${item['model'] ?? 'N/A'}'),
              Text('Fecha de Compra: ${item['purchase_date'] ?? 'N/A'}'),
              Text('Vencimiento Garantía: ${item['warranty_expiry'] ?? 'N/A'}'),
              Text('Último Mantenimiento: ${item['last_maintenance'] ?? 'N/A'}'),
              Text('Próximo Mantenimiento: ${item['next_maintenance'] ?? 'N/A'}'),
              Text('Notas: ${item['notes'] ?? 'N/A'}'),
              Text('Última Verificación: ${item['updated_at'] ?? 'N/A'}'),
              if (item['image_url'] != null) Image.network(item['image_url']),
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

  void _updateItemStatus(Map<String, dynamic> item) {
    final isGroup = item['item_type'] == 'group';
    int quantityExpected = item['quantity'] ?? 1;
    int quantityFound = isGroup ? 0 : quantityExpected; // Start with 0 for groups to force manual input
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
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  value: newStatus,
                  items: ['good', 'damaged', 'missing'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_statusTranslations[status] ?? status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      newStatus = value!;
                      if (value == 'good' && !isGroup) {
                        quantityFound = quantityExpected;
                        quantityDamaged = 0;
                        quantityMissing = 0;
                      } else if (value == 'damaged' && !isGroup) {
                        quantityFound = 0;
                        quantityDamaged = quantityExpected;
                        quantityMissing = 0;
                      } else if (value == 'missing' && !isGroup) {
                        quantityFound = 0;
                        quantityDamaged = 0;
                        quantityMissing = quantityExpected;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isGroup) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Gestión de Cantidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        _buildQuantityRow('Encontrados', quantityFound, (value) {
                          setDialogState(() {
                            quantityFound = value;
                            // Auto-adjust missing quantity
                            int totalAccounted = quantityFound + quantityDamaged;
                            quantityMissing = (quantityExpected - totalAccounted).clamp(0, quantityExpected);
                          });
                        }),
                        _buildQuantityRow('Dañados', quantityDamaged, (value) {
                          setDialogState(() {
                            quantityDamaged = value;
                            // Auto-adjust missing quantity
                            int totalAccounted = quantityFound + quantityDamaged;
                            quantityMissing = (quantityExpected - totalAccounted).clamp(0, quantityExpected);
                          });
                        }),
                        _buildQuantityRow('Faltantes', quantityMissing, (value) {
                          setDialogState(() {
                            quantityMissing = value;
                            // Auto-adjust found quantity
                            int totalAccounted = quantityDamaged + quantityMissing;
                            quantityFound = (quantityExpected - totalAccounted).clamp(0, quantityExpected);
                          });
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total esperado:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$quantityExpected', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total reportado:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${quantityFound + quantityDamaged + quantityMissing}', 
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold,
                                   color: (quantityFound + quantityDamaged + quantityMissing) == quantityExpected 
                                     ? Colors.green : Colors.red
                                 )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Item Individual', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Cantidad: $quantityExpected'),
                        Text('Estado seleccionado: ${_statusTranslations[newStatus] ?? newStatus}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                    hintText: 'Observaciones adicionales...',
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
                if (isGroup && quantityFound + quantityDamaged + quantityMissing != quantityExpected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Las cantidades deben sumar $quantityExpected. Actual: ${quantityFound + quantityDamaged + quantityMissing}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (quantityFound + quantityDamaged + quantityMissing == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe especificar al menos una cantidad'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  final environmentId = authProvider.currentUser!.environmentId.toString();
                  
                  final checkItemData = {
                    'item_id': item['id'].toString(), // Ensure UUID is string
                    'status': newStatus,
                    'quantity_expected': quantityExpected,
                    'quantity_found': quantityFound,
                    'quantity_damaged': quantityDamaged,
                    'quantity_missing': quantityMissing,
                    'environment_id': environmentId,
                  };
                  
                  // Only add notes if not empty
                  if (notes.isNotEmpty) {
                    checkItemData['notes'] = notes;
                  }
                  
                  print('[v0] Creating inventory check item with data: $checkItemData'); // Debug log
                  
                  await _apiService.post('/api/inventory-check-items/', checkItemData);
                  
                  String updatedStatus = newStatus;
                  if (quantityMissing > 0 && quantityFound == 0 && quantityDamaged == 0) {
                    updatedStatus = 'lost';
                  } else if (quantityDamaged > 0 && quantityFound == 0) {
                    updatedStatus = 'damaged';
                  } else if (quantityFound > 0 && quantityDamaged == 0 && quantityMissing == 0) {
                    updatedStatus = 'available';
                  } else if (quantityDamaged > 0 || quantityMissing > 0) {
                    updatedStatus = 'damaged';
                  }
                  
                  final updateData = {
                    'quantity': quantityFound + quantityDamaged,
                    'status': updatedStatus,
                  };
                  
                  print('[v0] Updating inventory item with data: $updateData'); // Debug log
                  
                  await _apiService.put('$inventoryEndpoint${item['id']}', updateData);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item actualizado: ${_statusTranslations[newStatus] ?? newStatus}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  print('[v0] Error updating item status: $e'); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                color: value > 0 ? Colors.red : Colors.grey,
              ),
              Container(
                width: 40,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(value + 1),
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckDialog() {
    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un horario para realizar la verificación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Verificación de Inventario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas iniciar una nueva verificación de inventario?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horario seleccionado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_schedules.firstWhere((s) => s['id'].toString() == _selectedScheduleId)['program'] ?? 'N/A'),
                  Text('Hora: ${_formatColombianTime(_schedules.firstWhere((s) => s['id'].toString() == _selectedScheduleId)['start_time'])} - ${_formatColombianTime(_schedules.firstWhere((s) => s['id'].toString() == _selectedScheduleId)['end_time'])}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cleaningNotesController,
              decoration: const InputDecoration(
                labelText: 'Notas de limpieza/observaciones',
                border: OutlineInputBorder(),
                hintText: 'Observaciones generales del ambiente...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final checkData = {
                  'environment_id': authProvider.currentUser!.environmentId,
                  'schedule_id': int.parse(_selectedScheduleId!),
                  'check_date': DateTime.now().toIso8601String().split('T')[0],
                  'check_time': TimeOfDay.now().format(context),
                  'status': 'pending',
                  'cleaning_notes': _cleaningNotesController.text.isNotEmpty ? _cleaningNotesController.text : null,
                };

                await _apiService.post(inventoryChecksEndpoint, checkData);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verificación iniciada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
                _fetchData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al iniciar verificación: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Iniciar Verificación'),
          ),
        ],
      ),
    );
  }

  void _showReportDamageDialog() {
    String description = '';
    String priority = 'medium';
    String equipmentName = '';
    String equipmentBrand = '';
    String equipmentModel = '';
    String equipmentLocation = '';
    Map<String, dynamic>? selectedItem;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar Problema/Daño'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(),
                  ),
                  value: priority,
                  items: [
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (value) => setDialogState(() => priority = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>?>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Item (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedItem,
                  items: [
                    DropdownMenuItem(value: null, child: Text('Equipo no registrado')),
                    ..._items.map((item) => DropdownMenuItem<Map<String, dynamic>?>(
                      value: item,
                      child: Text('${item['name']} - ${item['internal_code'] ?? item['id']}'),
                    )).toList(),
                  ],
                  onChanged: (value) => setDialogState(() => selectedItem = value),
                ),
                const SizedBox(height: 16),
                if (selectedItem == null) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Equipo',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => equipmentName = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => equipmentBrand = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => equipmentModel = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => equipmentLocation = value,
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción del Problema',
                    border: OutlineInputBorder(),
                    hintText: 'Describe detalladamente el problema...',
                  ),
                  maxLines: 4,
                  onChanged: (value) => description = value,
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
                if (description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La descripción es obligatoria'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedItem == null && equipmentName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un item o especificar el nombre del equipo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final requestData = {
                    'description': description,
                    'priority': priority,
                    'environment_id': authProvider.currentUser!.environmentId,
                    'requested_by': authProvider.currentUser!.id,
                  };

                  if (selectedItem != null) {
                    requestData['item_id'] = selectedItem!['id'];
                  } else {
                    requestData['equipment_name'] = equipmentName;
                    requestData['equipment_brand'] = equipmentBrand.isNotEmpty ? equipmentBrand : null;
                    requestData['equipment_model'] = equipmentModel.isNotEmpty ? equipmentModel : null;
                    requestData['equipment_location'] = equipmentLocation.isNotEmpty ? equipmentLocation : null;
                  }

                  await _apiService.post('/api/maintenance-requests/', requestData);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud de mantenimiento enviada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al enviar solicitud: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmInstructorCheck(Map<String, dynamic> check) {
    String instructorNotes = '';
    bool approved = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirmar Verificación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Check ID: ${check['id']}'),
              Text('Fecha: ${check['check_date']}'),
              Text('Hora: ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Aprobar'),
                      value: true,
                      groupValue: approved,
                      onChanged: (value) => setDialogState(() => approved = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Rechazar'),
                      value: false,
                      groupValue: approved,
                      onChanged: (value) => setDialogState(() => approved = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notas del Instructor',
                  border: OutlineInputBorder(),
                  hintText: 'Observaciones adicionales...',
                ),
                maxLines: 3,
                onChanged: (value) => instructorNotes = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updateData = {
                    'status': approved ? 'supervisor_review' : 'incomplete',
                    'instructor_notes': instructorNotes.isNotEmpty ? instructorNotes : null,
                    'instructor_approved': approved,
                  };

                  await _apiService.put('$inventoryChecksEndpoint${check['id']}', updateData);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(approved ? 'Verificación aprobada' : 'Verificación rechazada'),
                      backgroundColor: approved ? Colors.green : Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: approved ? AppColors.success : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(approved ? 'Aprobar' : 'Rechazar'),
            ),
          ],
        ),
      ),
    );
  }

  void _reviewSupervisorCheck(Map<String, dynamic> check) {
    String supervisorNotes = '';
    String finalStatus = 'complete';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Revisión Final - Supervisor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check ID: ${check['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Fecha: ${check['check_date']}'),
                Text('Hora: ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
                if (check['instructor_notes'] != null) ...[
                  const SizedBox(height: 12),
                  Text('Notas del Instructor:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(check['instructor_notes']),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Estado Final',
                    border: OutlineInputBorder(),
                  ),
                  value: finalStatus,
                  items: [
                    DropdownMenuItem(value: 'complete', child: Text('Completo')),
                    DropdownMenuItem(value: 'issues', child: Text('Con Problemas')),
                    DropdownMenuItem(value: 'incomplete', child: Text('Incompleto')),
                  ],
                  onChanged: (value) => setDialogState(() => finalStatus = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notas del Supervisor',
                    border: OutlineInputBorder(),
                    hintText: 'Observaciones finales...',
                  ),
                  maxLines: 3,
                  onChanged: (value) => supervisorNotes = value,
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
                try {
                  final updateData = {
                    'status': finalStatus,
                    'supervisor_notes': supervisorNotes.isNotEmpty ? supervisorNotes : null,
                    'supervisor_approved': finalStatus == 'complete',
                  };

                  await _apiService.put('$inventoryChecksEndpoint${check['id']}', updateData);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Revisión completada: ${_statusTranslations[finalStatus] ?? finalStatus}'),
                      backgroundColor: finalStatus == 'complete' ? Colors.green : Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finalizar Revisión'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckDetails(Map<String, dynamic> check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Verificación #${check['id']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Estado', _statusTranslations[check['status']] ?? check['status']),
              _buildDetailRow('Fecha', check['check_date'] ?? 'N/A'),
              _buildDetailRow('Hora', _formatColombianTime(check['check_time'] ?? '00:00:00')),
              if (check['total_items'] != null) ...[
                const Divider(),
                Text('Estadísticas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _buildDetailRow('Total Items', '${check['total_items']}'),
                _buildDetailRow('Items Buenos', '${check['items_good'] ?? 0}'),
                _buildDetailRow('Items Dañados', '${check['items_damaged'] ?? 0}'),
                _buildDetailRow('Items Faltantes', '${check['items_missing'] ?? 0}'),
              ],
              if (check['cleaning_notes'] != null) ...[
                const Divider(),
                Text('Notas de Limpieza:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(check['cleaning_notes']),
              ],
              if (check['instructor_notes'] != null) ...[
                const Divider(),
                Text('Notas del Instructor:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(check['instructor_notes']),
                _buildDetailRow('Aprobado por Instructor', check['instructor_approved'] == true ? 'Sí' : 'No'),
              ],
              if (check['supervisor_notes'] != null) ...[
                const Divider(),
                Text('Notas del Supervisor:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(check['supervisor_notes']),
                _buildDetailRow('Aprobado por Supervisor', check['supervisor_approved'] == true ? 'Sí' : 'No'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (check['status'] == 'instructor_review' && Provider.of<AuthProvider>(context, listen: false).currentUser?.role == 'instructor')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmInstructorCheck(check);
              },
              child: const Text('Revisar'),
            ),
          if (check['status'] == 'supervisor_review' && Provider.of<AuthProvider>(context, listen: false).currentUser?.role == 'supervisor')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _reviewSupervisorCheck(check);
              },
              child: const Text('Revisar'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
