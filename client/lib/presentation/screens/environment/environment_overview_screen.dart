import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
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
  State<EnvironmentOverviewScreen> createState() =>
      _EnvironmentOverviewScreenState();
}

class _EnvironmentOverviewScreenState extends State<EnvironmentOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService; // Cambiar a late
  late TabController _tabController;
  List<dynamic> _inventory = [];
  List<dynamic> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicializar ApiService con AuthProvider
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print(
        'Fetching data for environment: ${widget.environmentId}, Token: ${authProvider.token}',
      );

      // Solo incluir environment_id si es válido
      final queryParams = widget.environmentId.isNotEmpty
          ? {'environment_id': widget.environmentId}
          : null;

      final inventory = await _apiService.get(
        inventoryEndpoint,
        queryParams: queryParams,
      );
      final schedule = await _apiService.get(
        '/api/schedules/',
        queryParams: queryParams,
      );
      setState(() {
        _inventory = inventory;
        _schedule = schedule
            .map(
              (s) => {
                'time': '${s['start_time']} - ${s['end_time']}',
                'program': s['program'],
                'activity': s['topic'] ?? 'N/A',
                'instructor': s['instructor_id'],
                'students': s['student_count'],
              },
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in_use':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'damaged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  StatusType _getStatusType(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return StatusType.success;
      case 'in_use':
        return StatusType.info;
      case 'maintenance':
        return StatusType.warning;
      case 'damaged':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SenaAppBar(title: widget.environmentName, showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                                    _buildStatChip(
                                      'Equipos',
                                      '${_inventory.length}',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                      'Disponibles',
                                      '${_inventory.where((item) => item['status'] == 'available').length}',
                                      Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                      'En uso',
                                      '${_inventory.where((item) => item['status'] == 'in_use').length}',
                                      Colors.orange,
                                    ),
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (context, index) {
        final item = _inventory[index];
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
                            'Categoría',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item['category'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
                            item['last_maintenance'] ?? 'N/A',
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
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final item = _schedule[index];
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
                      item['time'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF00324D),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['students'] ?? 0} estudiantes',
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
                  item['program'] ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['activity'] ?? 'N/A',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
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
                      item['instructor'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
    final totalEquipment = _inventory.length;
    final available = _inventory
        .where((item) => item['status'] == 'available')
        .length;
    final inUse = _inventory.where((item) => item['status'] == 'in_use').length;
    final maintenance = _inventory
        .where((item) => item['status'] == 'maintenance')
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Equipos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalEquipment.toString(),
                  Colors.blue,
                  Icons.devices,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Disponibles',
                  available.toString(),
                  Colors.green,
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En Uso',
                  inUse.toString(),
                  Colors.orange,
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Mantenimiento',
                  maintenance.toString(),
                  Colors.red,
                  Icons.build_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Utilización del Ambiente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SenaCard(
            child: Column(
              children: [
                _buildUtilizationRow(
                  'Disponibilidad',
                  totalEquipment > 0
                      ? '${((available / totalEquipment) * 100).toInt()}%'
                      : '0%',
                  Colors.green,
                ),
                const Divider(),
                _buildUtilizationRow(
                  'En Uso',
                  totalEquipment > 0
                      ? '${((inUse / totalEquipment) * 100).toInt()}%'
                      : '0%',
                  Colors.orange,
                ),
                const Divider(),
                _buildUtilizationRow(
                  'Mantenimiento',
                  totalEquipment > 0
                      ? '${((maintenance / totalEquipment) * 100).toInt()}%'
                      : '0%',
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return SenaCard(
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
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
