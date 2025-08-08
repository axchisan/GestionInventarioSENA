import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';

class InventoryAlertsScreen extends StatefulWidget {
  const InventoryAlertsScreen({Key? key}) : super(key: key);

  @override
  State<InventoryAlertsScreen> createState() => _InventoryAlertsScreenState();
}

class _InventoryAlertsScreenState extends State<InventoryAlertsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPriority = 'Todas';
  String _selectedType = 'Todas';

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': '001',
      'title': 'Stock Bajo - Multímetros',
      'description': 'Solo quedan 2 multímetros disponibles en el Laboratorio de Electrónica',
      'type': 'Stock Bajo',
      'priority': 'Alta',
      'timestamp': '2024-01-15 09:30',
      'location': 'Lab. Electrónica',
      'isRead': false,
      'icon': Icons.warning,
      'color': Colors.orange,
    },
    {
      'id': '002',
      'title': 'Equipo Vencido - Extintor',
      'description': 'El extintor EXT-001 ha vencido y requiere mantenimiento inmediato',
      'type': 'Mantenimiento',
      'priority': 'Crítica',
      'timestamp': '2024-01-15 08:45',
      'location': 'Taller Mecánica',
      'isRead': false,
      'icon': Icons.error,
      'color': Colors.red,
    },
    {
      'id': '003',
      'title': 'Préstamo Vencido',
      'description': 'El taladro TD-005 no ha sido devuelto por Juan Pérez',
      'type': 'Préstamo',
      'priority': 'Media',
      'timestamp': '2024-01-15 07:20',
      'location': 'Taller Carpintería',
      'isRead': true,
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'id': '004',
      'title': 'Nuevo Equipo Registrado',
      'description': 'Se ha agregado una nueva sierra circular al inventario',
      'type': 'Información',
      'priority': 'Baja',
      'timestamp': '2024-01-14 16:15',
      'location': 'Taller Carpintería',
      'isRead': true,
      'icon': Icons.info,
      'color': Colors.green,
    },
    {
      'id': '005',
      'title': 'Calibración Pendiente',
      'description': '5 equipos requieren calibración en los próximos 7 días',
      'type': 'Mantenimiento',
      'priority': 'Media',
      'timestamp': '2024-01-14 14:30',
      'location': 'Múltiples',
      'isRead': false,
      'icon': Icons.build,
      'color': Colors.amber,
    },
  ];

  final List<Map<String, dynamic>> _configurations = [
    {
      'type': 'Stock Bajo',
      'enabled': true,
      'threshold': 5,
      'description': 'Alertar cuando el stock sea menor a',
    },
    {
      'type': 'Mantenimiento',
      'enabled': true,
      'threshold': 7,
      'description': 'Alertar con días de anticipación',
    },
    {
      'type': 'Préstamos Vencidos',
      'enabled': true,
      'threshold': 1,
      'description': 'Alertar después de días de retraso',
    },
    {
      'type': 'Calibración',
      'enabled': false,
      'threshold': 30,
      'description': 'Alertar con días de anticipación',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                      '${_alerts.where((alert) => !alert['isRead']).length}',
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
    final filteredAlerts = _alerts.where((alert) {
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return _buildAlertCard(alert);
                  },
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
              items: ['Todas', 'Crítica', 'Alta', 'Media', 'Baja']
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
              items: ['Todas', 'Stock Bajo', 'Mantenimiento', 'Préstamo', 'Información']
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
                  onChanged: (value) {
                    setState(() {
                      config['enabled'] = value;
                    });
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
                        config['threshold'] = int.tryParse(value) ?? config['threshold'];
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

  void _markAsRead(Map<String, dynamic> alert) {
    setState(() {
      alert['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var alert in _alerts) {
        alert['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las alertas marcadas como leídas')),
    );
  }
}
