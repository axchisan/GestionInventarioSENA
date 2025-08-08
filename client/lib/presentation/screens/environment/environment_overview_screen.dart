import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';

class EnvironmentOverviewScreen extends StatefulWidget {
  final String environmentId;
  final String environmentName;

  const EnvironmentOverviewScreen({
    Key? key,
    required this.environmentId,
    required this.environmentName,
  }) : super(key: key);

  @override
  State<EnvironmentOverviewScreen> createState() => _EnvironmentOverviewScreenState();
}

class _EnvironmentOverviewScreenState extends State<EnvironmentOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> inventory = [
    {
      'id': 'PC001',
      'name': 'Computador Dell OptiPlex',
      'status': 'Disponible',
      'condition': 'Bueno',
      'lastMaintenance': '2024-01-10',
      'assignedTo': null,
    },
    {
      'id': 'PC002',
      'name': 'Computador HP ProDesk',
      'status': 'En uso',
      'condition': 'Excelente',
      'lastMaintenance': '2024-01-08',
      'assignedTo': 'Juan Pérez',
    },
    {
      'id': 'MON001',
      'name': 'Monitor Samsung 24"',
      'status': 'Disponible',
      'condition': 'Bueno',
      'lastMaintenance': '2024-01-05',
      'assignedTo': null,
    },
    {
      'id': 'PRJ001',
      'name': 'Proyector Epson',
      'status': 'Mantenimiento',
      'condition': 'Regular',
      'lastMaintenance': '2024-01-15',
      'assignedTo': null,
    },
  ];

  final List<Map<String, dynamic>> schedule = [
    {
      'time': '07:00 - 09:00',
      'program': 'Técnico en Sistemas',
      'instructor': 'Carlos Rodríguez',
      'students': 25,
      'activity': 'Programación Web',
    },
    {
      'time': '09:00 - 11:00',
      'program': 'Análisis y Desarrollo',
      'instructor': 'Ana García',
      'students': 30,
      'activity': 'Base de Datos',
    },
    {
      'time': '11:00 - 13:00',
      'program': 'Técnico en Sistemas',
      'instructor': 'Luis Martínez',
      'students': 28,
      'activity': 'Redes de Computadores',
    },
    {
      'time': '14:00 - 16:00',
      'program': 'Análisis y Desarrollo',
      'instructor': 'María López',
      'students': 22,
      'activity': 'Desarrollo Móvil',
    },
    {
      'time': '16:00 - 18:00',
      'program': 'Técnico en Sistemas',
      'instructor': 'Pedro Sánchez',
      'students': 26,
      'activity': 'Soporte Técnico',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'en uso':
        return Colors.blue;
      case 'mantenimiento':
        return Colors.orange;
      case 'dañado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excelente':
        return Colors.green;
      case 'bueno':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'malo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  StatusType _getStatusType(String? status) {
    switch (status?.toLowerCase()) {
      case 'disponible':
        return StatusType.success;
      case 'en uso':
        return StatusType.info;
      case 'mantenimiento':
        return StatusType.warning;
      case 'dañado':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  StatusType _getConditionType(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'excelente':
        return StatusType.success;
      case 'bueno':
        return StatusType.info;
      case 'regular':
        return StatusType.warning;
      case 'malo':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SenaAppBar(
        title: widget.environmentName,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Información del ambiente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00324D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/sena-logo.png',
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
                            widget.environmentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${widget.environmentId}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatChip('Equipos', '${inventory.length}', Colors.blue),
                              const SizedBox(width: 8),
                              _buildStatChip('Disponibles', '${inventory.where((item) => item['status'] == 'Disponible').length}', Colors.green),
                              const SizedBox(width: 8),
                              _buildStatChip('En uso', '${inventory.where((item) => item['status'] == 'En uso').length}', Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00324D),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00324D),
              tabs: const [
                Tab(text: 'Inventario'),
                Tab(text: 'Horarios'),
                Tab(text: 'Estadísticas'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildScheduleTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: ${item['id']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: item['status'],
                      type: _getStatusType(item['status']),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Condición',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          StatusBadge(
                            text: item['condition'],
                            type: _getConditionType(item['condition']),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Último mantenimiento',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item['lastMaintenance'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item['assignedTo'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Asignado a: ${item['assignedTo']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final item = schedule[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['time'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF00324D),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['students']} estudiantes',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['program'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['activity'],
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['instructor'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    final totalEquipment = inventory.length;
    final available = inventory.where((item) => item['status'] == 'Disponible').length;
    final inUse = inventory.where((item) => item['status'] == 'En uso').length;
    final maintenance = inventory.where((item) => item['status'] == 'Mantenimiento').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Equipos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', totalEquipment.toString(), Colors.blue, Icons.devices),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Disponibles', available.toString(), Colors.green, Icons.check_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('En Uso', inUse.toString(), Colors.orange, Icons.person_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Mantenimiento', maintenance.toString(), Colors.red, Icons.build_outlined),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Utilización del Ambiente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SenaCard(
            child: Column(
              children: [
                _buildUtilizationRow('Disponibilidad', '${((available / totalEquipment) * 100).toInt()}%', Colors.green),
                const Divider(),
                _buildUtilizationRow('En Uso', '${((inUse / totalEquipment) * 100).toInt()}%', Colors.orange),
                const Divider(),
                _buildUtilizationRow('Mantenimiento', '${((maintenance / totalEquipment) * 100).toInt()}%', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return SenaCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationRow(String label, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}