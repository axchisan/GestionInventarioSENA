import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/alerts/alert_detail_modal.dart';
import '../../widgets/alerts/maintenance_alert_detail_modal.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/services/alert_settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/alert_settings_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/inventory_check_item_model.dart';
import '../../../data/models/maintenance_request_model.dart';
import '../../../core/theme/app_colors.dart';

class InventoryAlertsScreen extends StatefulWidget {
  const InventoryAlertsScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAlertsScreen> createState() => _InventoryAlertsScreenState();
}

class _InventoryAlertsScreenState extends State<InventoryAlertsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPriority = 'Todas';
  String _selectedType = 'Todas';
  
  List<AlertModel> _systemAlerts = [];
  List<NotificationModel> _maintenanceNotifications = [];
  List<InventoryCheckItemModel> _inventoryIssues = [];
  List<AlertSettingsModel> _alertSettings = [];
  
  bool _isLoading = true;
  bool _isLoadingSettings = true;
  String? _error;
  int _totalUnresolved = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlertsData();
    _loadAlertSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlertsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AlertService.getCombinedAlertsData();
      
      setState(() {
        _systemAlerts = data['systemAlerts'] as List<AlertModel>;
        _maintenanceNotifications = data['maintenanceNotifications'] as List<NotificationModel>;
        _inventoryIssues = data['inventoryIssues'] as List<InventoryCheckItemModel>;
        _totalUnresolved = data['totalUnresolved'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar las alertas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlertSettings() async {
    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final settings = await AlertSettingsService.getUserAlertSettings();
      setState(() {
        _alertSettings = settings;
        _isLoadingSettings = false;
      });
    } catch (e) {
      print('Error loading alert settings: $e');
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  List<Map<String, dynamic>> get _combinedAlerts {
    List<Map<String, dynamic>> combined = [];
    
    // Add system alerts
    for (var alert in _systemAlerts) {
      combined.add({
        'id': alert.id,
        'title': alert.title,
        'description': alert.message,
        'type': alert.typeText,
        'priority': alert.priorityText,
        'timestamp': _formatDateTime(alert.createdAt),
        'location': alert.entityType ?? 'Sistema',
        'isRead': alert.isResolved,
        'icon': alert.typeIcon,
        'color': alert.priorityColor,
        'source': 'system_alert',
        'data': alert,
      });
    }
    
    // Add maintenance notifications
    for (var notification in _maintenanceNotifications) {
      combined.add({
        'id': notification.id,
        'title': notification.title,
        'description': notification.message,
        'type': notification.typeText,
        'priority': notification.priorityText,
        'timestamp': _formatDateTime(notification.createdAt),
        'location': 'Mantenimiento',
        'isRead': notification.isRead,
        'icon': notification.typeIcon,
        'color': notification.priorityColor,
        'source': 'notification',
        'data': notification,
      });
    }
    
    // Add inventory issues
    for (var issue in _inventoryIssues) {
      combined.add({
        'id': issue.id,
        'title': 'Problema en ${issue.itemName ?? 'Item'}',
        'description': 'Estado: ${issue.statusText}. ${issue.issueDescription}',
        'type': 'Verificación',
        'priority': issue.hasIssues ? 'Alta' : 'Media',
        'timestamp': _formatDateTime(issue.updatedAt),
        'location': issue.environmentName ?? 'Desconocido',
        'isRead': false,
        'icon': Icons.assignment_late,
        'color': issue.statusColor,
        'source': 'inventory_check',
        'data': issue,
      });
    }
    
    // Sort by timestamp (newest first)
    combined.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    return combined;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Inventario'),
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
          ),
          IconButton(
            onPressed: () {
              _loadAlertsData();
              _loadAlertSettings();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Alertas'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_totalUnresolved',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Configuración'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildConfigurationTab(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando alertas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlertsData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final filteredAlerts = _combinedAlerts.where((alert) {
      final matchesPriority = _selectedPriority == 'Todas' || alert['priority'] == _selectedPriority;
      final matchesType = _selectedType == 'Todas' || alert['type'] == _selectedType;
      return matchesPriority && matchesType;
    }).toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: filteredAlerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay alertas', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlertsData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildConfigurationTab() {
    if (_isLoadingSettings) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando configuraciones...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de Alertas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personaliza qué alertas quieres recibir y cómo',
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
          
          const SizedBox(height: 16),
          
          // Alert Types Configuration
          _buildAlertTypeSection('low_stock', 'Stock Bajo', 
              'Recibir alertas cuando el inventario esté por debajo del umbral', 
              Icons.inventory_2_outlined),
          
          const SizedBox(height: 12),
          
          _buildAlertTypeSection('maintenance_overdue', 'Mantenimiento Vencido', 
              'Alertas sobre equipos que requieren mantenimiento', 
              Icons.build_outlined),
          
          const SizedBox(height: 12),
          
          _buildAlertTypeSection('equipment_missing', 'Equipo Faltante', 
              'Notificaciones sobre equipos no encontrados en verificaciones', 
              Icons.error_outline),
          
          const SizedBox(height: 12),
          
          _buildAlertTypeSection('loan_overdue', 'Préstamo Vencido', 
              'Alertas sobre préstamos que no han sido devueltos a tiempo', 
              Icons.schedule_outlined),
          
          const SizedBox(height: 12),
          
          _buildAlertTypeSection('verification_pending', 'Verificación Pendiente', 
              'Recordatorios sobre verificaciones de inventario pendientes', 
              Icons.assignment_outlined),
          
          const SizedBox(height: 24),
          
          // Add new alert setting button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddAlertSettingDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Nueva Configuración'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTypeSection(String alertType, String title, String description, IconData icon) {
    final setting = _alertSettings.firstWhere(
      (s) => s.alertType == alertType,
      orElse: () => AlertSettingsModel(
        id: '',
        userId: '',
        alertType: alertType,
        isEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final hasExistingSetting = setting.id.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: setting.isEnabled,
                  onChanged: (value) => _toggleAlertSetting(alertType, value, hasExistingSetting ? setting.id : null),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            
            if (setting.isEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Threshold configuration for applicable alert types
              if (alertType == 'low_stock') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: setting.thresholdValue?.toString() ?? '5',
                        decoration: const InputDecoration(
                          labelText: 'Umbral mínimo',
                          border: OutlineInputBorder(),
                          suffixText: 'unidades',
                        ),
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (value) {
                          final threshold = int.tryParse(value) ?? 5;
                          _updateAlertThreshold(setting.id, threshold);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Se enviará una alerta cuando el stock esté por debajo de este valor',
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                  ),
                ),
              ],
              
              // Notification methods
              const SizedBox(height: 16),
              Text(
                'Métodos de notificación:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Push'),
                    selected: setting.notificationMethods?.contains('push') ?? false,
                    onSelected: (selected) => _toggleNotificationMethod(setting.id, 'push', selected),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                  FilterChip(
                    label: const Text('Email'),
                    selected: setting.notificationMethods?.contains('email') ?? false,
                    onSelected: (selected) => _toggleNotificationMethod(setting.id, 'email', selected),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildFilters() {
    final availableTypes = ['Todas'];
    final availablePriorities = ['Todas', 'Crítica', 'Alta', 'Media', 'Baja'];
    
    // Extract unique types from combined alerts
    for (var alert in _combinedAlerts) {
      final type = alert['type'] as String;
      if (!availableTypes.contains(type)) {
        availableTypes.add(type);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: availablePriorities
                  .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: availableTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert['isRead'] ? 1 : 3,
      child: InkWell(
        onTap: () => _showAlertDetail(alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alert['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alert['icon'],
                      color: alert['color'],
                      size: 20,
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
                                alert['title'],
                                style: TextStyle(
                                  fontWeight: alert['isRead'] ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (!alert['isRead'])
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(alert['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert['priority'],
                      style: TextStyle(
                        color: _getPriorityColor(alert['priority']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert['type'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    alert['location'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    alert['timestamp'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAlertDetail(alert),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalles'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  if (!alert['isRead'])
                    TextButton(
                      onPressed: () => _markAsRead(alert),
                      child: const Text('Marcar como leída'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Crítica':
        return Colors.red;
      case 'Alta':
        return Colors.orange;
      case 'Media':
        return Colors.blue;
      case 'Baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleAlertSetting(String alertType, bool enabled, String? settingId) async {
    try {
      if (settingId != null) {
        // Update existing setting
        await AlertSettingsService.updateAlertSetting(
          settingId: settingId,
          isEnabled: enabled,
        );
      } else {
        // Create new setting
        await AlertSettingsService.createAlertSetting(
          alertType: alertType,
          isEnabled: enabled,
          notificationMethods: ['push'],
        );
      }
      
      // Reload settings
      await _loadAlertSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Alerta activada' : 'Alerta desactivada'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar configuración: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateAlertThreshold(String settingId, int threshold) async {
    try {
      await AlertSettingsService.updateAlertSetting(
        settingId: settingId,
        thresholdValue: threshold,
      );
      
      await _loadAlertSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Umbral actualizado a $threshold'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar umbral: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleNotificationMethod(String settingId, String method, bool enabled) async {
    try {
      final setting = _alertSettings.firstWhere((s) => s.id == settingId);
      final methods = List<String>.from(setting.notificationMethods ?? []);
      
      if (enabled) {
        if (!methods.contains(method)) methods.add(method);
      } else {
        methods.remove(method);
      }
      
      await AlertSettingsService.updateAlertSetting(
        settingId: settingId,
        notificationMethods: methods,
      );
      
      await _loadAlertSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar método de notificación: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAlertDetail(Map<String, dynamic> alert) async {
    final source = alert['source'] as String;
    
    if (source == 'system_alert') {
      final alertModel = alert['data'] as AlertModel;
      showDialog(
        context: context,
        builder: (context) => AlertDetailModal(
          alert: alertModel,
          onResolve: () async {
            final success = await AlertService.resolveAlert(alertModel.id);
            if (success) {
              setState(() {
                alert['isRead'] = true;
                if (_totalUnresolved > 0) _totalUnresolved--;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alerta marcada como resuelta'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al resolver la alerta'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    } else if (source == 'notification') {
      final notification = alert['data'] as NotificationModel;
      
      if (notification.isMaintenanceRelated && notification.actionUrl != null) {
        String? maintenanceId = _extractMaintenanceIdFromUrl(notification.actionUrl!);
        
        if (maintenanceId != null) {
          // Show loading dialog while fetching maintenance request details
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          try {
            final maintenanceRequest = await MaintenanceService.getMaintenanceRequestById(maintenanceId);
            Navigator.of(context).pop(); // Close loading dialog
            
            if (maintenanceRequest != null) {
              showDialog(
                context: context,
                builder: (context) => MaintenanceAlertDetailModal(
                  maintenanceRequest: maintenanceRequest,
                  onClose: () => Navigator.of(context).pop(),
                ),
              );
            } else {
              _showSimpleAlertDialog(alert);
            }
          } catch (e) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar detalles: $e'),
                backgroundColor: AppColors.error,
              ),
            );
            _showSimpleAlertDialog(alert);
          }
        } else {
          _showSimpleAlertDialog(alert);
        }
      } else {
        _showSimpleAlertDialog(alert);
      }
    } else {
      _showSimpleAlertDialog(alert);
    }
  }

  void _showSimpleAlertDialog(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert['description']),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Tipo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(alert['type']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Prioridad: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(alert['priority']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert['priority'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Ubicación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(alert['location']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Fecha: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(alert['timestamp']),
              ],
            ),
          ],
        ),
        actions: [
          if (!alert['isRead'])
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsRead(alert);
              },
              child: const Text('Marcar como leída'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAddAlertSettingDialog() {
    // Implementation for adding custom alert settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Configuración de Alerta'),
        content: const Text('Esta funcionalidad estará disponible próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(Map<String, dynamic> alert) async {
    final source = alert['source'] as String;
    final id = alert['id'] as String;
    
    bool success = false;
    
    switch (source) {
      case 'system_alert':
        success = await AlertService.resolveAlert(id);
        break;
      case 'notification':
        success = await NotificationService.markAsRead(id);
        break;
      case 'inventory_check':
        // For inventory checks, we just mark as read locally
        success = true;
        break;
    }
    
    if (success) {
      setState(() {
        alert['isRead'] = true;
        if (_totalUnresolved > 0) _totalUnresolved--;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al marcar como leída')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadAlerts = _combinedAlerts.where((alert) => !alert['isRead']).toList();
    
    for (var alert in unreadAlerts) {
      await _markAsRead(alert);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las alertas marcadas como leídas')),
    );
  }

  String? _extractMaintenanceIdFromUrl(String actionUrl) {
    try {
      // Assuming actionUrl format like "/maintenance/123" or contains maintenance ID
      final uri = Uri.parse(actionUrl);
      final segments = uri.pathSegments;
      
      // Look for maintenance ID in path segments
      for (int i = 0; i < segments.length; i++) {
        if (segments[i] == 'maintenance' && i + 1 < segments.length) {
          return segments[i + 1];
        }
      }
      
      // Alternative: check if actionUrl contains a UUID pattern
      final uuidPattern = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');
      final match = uuidPattern.firstMatch(actionUrl);
      if (match != null) {
        return match.group(0);
      }
      
      return null;
    } catch (e) {
      print('Error extracting maintenance ID from URL: $e');
      return null;
    }
  }
}
