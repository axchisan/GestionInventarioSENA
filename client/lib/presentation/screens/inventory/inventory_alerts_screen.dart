import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/inventory_check_item_model.dart';

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
  List<Map<String, dynamic>> _configurations = [];
  
  bool _isLoading = true;
  String? _error;
  int _totalUnresolved = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlertsData();
    _loadConfigurations();
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

  Future<void> _loadConfigurations() async {
  try {
    final configs = await AlertService.getAlertConfigurations();
    setState(() {
      _configurations = configs;
    });
  } catch (e) {
    print('Error loading configurations: $e');
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
            onPressed: _loadAlertsData,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _configurations.length,
      itemBuilder: (context, index) {
        final config = _configurations[index];
        return _buildConfigurationCard(config);
      },
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
        onTap: () => _markAsRead(alert),
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

  Widget _buildConfigurationCard(Map<String, dynamic> config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    config['type'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Switch(
                  value: config['enabled'],
                  onChanged: (value) async {
                    final success = await AlertService.updateAlertConfiguration(
                      type: config['type'],
                      enabled: value,
                      threshold: config['threshold'],
                    );
                    
                    if (success) {
                      setState(() {
                        config['enabled'] = value;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al actualizar configuración')),
                      );
                    }
                  },
                  activeColor: const Color(0xFF00A651),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config['description'],
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (config['enabled']) ...[ 
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: config['threshold'].toString(),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newThreshold = int.tryParse(value) ?? config['threshold'];
                        config['threshold'] = newThreshold;
                      },
                      onFieldSubmitted: (value) async {
                        final newThreshold = int.tryParse(value) ?? config['threshold'];
                        final success = await AlertService.updateAlertConfiguration(
                          type: config['type'],
                          enabled: config['enabled'],
                          threshold: newThreshold,
                        );
                        
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al actualizar umbral')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    config['type'] == 'Stock Bajo' ? 'unidades' : 'días',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
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
}
