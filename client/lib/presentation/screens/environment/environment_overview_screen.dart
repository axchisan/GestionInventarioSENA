import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';

class EnvironmentOverviewScreen extends StatefulWidget {
  const EnvironmentOverviewScreen({Key? key}) : super(key: key);

  @override
  State<EnvironmentOverviewScreen> createState() =>
      _EnvironmentOverviewScreenState();
}

class _EnvironmentOverviewScreenState extends State<EnvironmentOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late TabController _tabController;
  List<dynamic> _inventory = [];
  List<dynamic> _schedules = [];
  List<dynamic> _checks = [];
  bool _isLoading = true;
  final DateFormat _colombianTimeFormat = DateFormat('hh:mm a');
  String _environmentId = '';
  Map<String, dynamic>? _environment;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user?.environmentId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vincula un ambiente para acceder al overview'),
          ),
        );
        return;
      }
      _environmentId = user!.environmentId.toString();

      final environment = await _apiService.getSingle(
        '$environmentsEndpoint$_environmentId',
      );

      final queryParams = {'environment_id': _environmentId};

      final inventory = await _apiService.get(
        inventoryEndpoint,
        queryParams: queryParams,
      );
      final schedules = await _apiService.get(
        '/api/schedules/',
        queryParams: queryParams,
      );
      final checks = await _apiService.get(
        inventoryChecksEndpoint,
        queryParams: queryParams,
      );
      setState(() {
        _environment = environment;
        _inventory = inventory;
        _schedules = schedules;
        _checks = checks;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      // ignore: unused_element
      setState() {
        _isLoading = false;
      };
    }
  }

  String _formatColombianTime(String timeStr) {
    try {
      final dateTime = DateFormat('HH:mm').parse(timeStr); // Parsea 24h
      return _colombianTimeFormat.format(dateTime); // Formato 12h AM/PM
    } catch (e) {
      return timeStr; // Fallback
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
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentUser?.role ?? '';

    return Scaffold(
      appBar: SenaAppBar(title: 'Ambiente'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
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
                                  'assets/images/sena_logo.png',
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
                                    _environment?['name'] ?? 'Ambiente $_environmentId',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'ID: $_environmentId',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Ubicación: ${_environment?['location'] ?? 'N/A'}',
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
                                        '${_calculateTotalItems()}',
                                        Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        'Disponibles',
                                        '${_calculateAvailableItems()}',
                                        Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        'En uso',
                                        '${_calculateInUseItems()}',
                                        Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        'Dañados/Faltantes',
                                        '${_calculateDamagedMissingItems()}',
                                        Colors.red,
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
                        _buildInventoryTab(role),
                        _buildScheduleTab(role),
                        _buildStatsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: role == 'supervisor' || role == 'admin'
          ? FloatingActionButton(
              onPressed: () {
                context.push(
                  '/add-inventory-item',
                  extra: {'environmentId': _environmentId},
                ).then((_) => _fetchData());
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  int _calculateTotalItems() {
    return _inventory.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  int _calculateAvailableItems() {
    return _inventory.fold(0, (sum, item) {
      if (item['status'] == 'available') {
        return sum + (item['quantity'] as int? ?? 1);
      }
      return sum;
    });
  }

  int _calculateInUseItems() {
    return _inventory.fold(0, (sum, item) {
      if (item['status'] == 'in_use') {
        return sum + (item['quantity'] as int? ?? 1);
      }
      return sum;
    });
  }

  int _calculateDamagedMissingItems() {
    return _inventory.fold(0, (sum, item) {
      if (item['status'] == 'damaged' || item['status'] == 'lost') {
        return sum + (item['quantity'] as int? ?? 1);
      }
      return sum;
    });
  }

  int _calculateCompletedChecks() {
    return _checks.where((check) => check['status'] == 'complete').length;
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

  Widget _buildInventoryTab(String role) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (context, index) {
        final item = _inventory[index];
        final isGroup = item['item_type'] == 'group';
        final totalQuantity = item['quantity'] ?? 1;
        final damagedQuantity = item['quantity_damaged'] ?? 0;
        final missingQuantity = item['quantity_missing'] ?? 0;
        final availableQuantity = totalQuantity - damagedQuantity - missingQuantity;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SenaCard(
            child: InkWell(
              onTap: () => _showItemDetails(item),
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
                              isGroup ? 'Grupo: ${item['quantity']} unidades' : 'ID: ${item['id']}',
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
                  if (isGroup) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado de Cantidades',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuantityIndicator(
                                  'Total',
                                  totalQuantity.toString(),
                                  AppColors.primary,
                                  Icons.inventory,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuantityIndicator(
                                  'Disponibles',
                                  availableQuantity.toString(),
                                  AppColors.success,
                                  Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuantityIndicator(
                                  'Dañados',
                                  damagedQuantity.toString(),
                                  AppColors.warning,
                                  Icons.broken_image,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuantityIndicator(
                                  'Faltantes',
                                  missingQuantity.toString(),
                                  AppColors.error,
                                  Icons.error_outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                  if (role == 'supervisor' || role == 'admin') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _editItem(item),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteItem(item),
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityIndicator(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    context.push('/edit-inventory-item', extra: {'item': item}).then((_) => _fetchData());
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
                await _apiService.delete(
                  '/api/inventory/${item['id']}',
                );
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
              Text('Categoría: ${item['category']}'),
              Text('Estado: ${item['status']}'),
              Text('Cantidad Total: ${item['quantity'] ?? 1}'),
              if ((item['quantity_damaged'] ?? 0) > 0)
                Text('Cantidad Dañada: ${item['quantity_damaged']}'),
              if ((item['quantity_missing'] ?? 0) > 0)
                Text('Cantidad Faltante: ${item['quantity_missing']}'),
              Text('Cantidad Disponible: ${(item['quantity'] ?? 1) - (item['quantity_damaged'] ?? 0) - (item['quantity_missing'] ?? 0)}'),
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

  Widget _buildScheduleTab(String role) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length + (role == 'instructor' || role == 'supervisor' ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _schedules.length && (role == 'instructor' || role == 'supervisor')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _addSchedule,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Horario'),
            ),
          );
        }
        final item = _schedules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SenaCard(
            child: InkWell(
              onTap: () => _showScheduleDetails(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatColombianTime(item['start_time'])} - ${_formatColombianTime(item['end_time'])}',
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
                          '${item['student_count'] ?? 0} estudiantes',
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
                    item['topic'] ?? 'N/A',
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
                        item['instructor_id'] ?? 'N/A',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (role == 'instructor' || role == 'supervisor') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _editSchedule(item),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteSchedule(item['id']),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScheduleDetails(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule['program']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${schedule['id']}'),
            Text('Horario: ${_formatColombianTime(schedule['start_time'])} - ${_formatColombianTime(schedule['end_time'])}'),
            Text('Día: ${schedule['day_of_week']}'),
            Text('Fecha Inicio: ${schedule['start_date']}'),
            Text('Fecha Fin: ${schedule['end_date']}'),
            Text('Tema: ${schedule['topic'] ?? 'N/A'}'),
            Text('Ficha: ${schedule['ficha']}'),
            Text('Estudiantes: ${schedule['student_count']}'),
            Text('Activo: ${schedule['is_active'] ? 'Sí' : 'No'}'),
          ],
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

  void _addSchedule() {
    String program = '';
    String ficha = '';
    String topic = '';
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();
    int dayOfWeek = 1;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    int studentCount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Horario'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Programa'),
                  onChanged: (value) => program = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ficha'),
                  onChanged: (value) => ficha = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Tema'),
                  onChanged: (value) => topic = value,
                ),
                ListTile(
                  title: Text('Inicio: ${startTime.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                      initialEntryMode: TimePickerEntryMode.dial, // Para formato visual
                    );
                    if (picked != null) {
                      setState(() {
                        startTime = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Fin: ${endTime.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                      initialEntryMode: TimePickerEntryMode.dial,
                    );
                    if (picked != null) {
                      setState(() {
                        endTime = picked;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text('Día ${i + 1}'))),
                  onChanged: (value) {
                    setState(() {
                      dayOfWeek = value!;
                    });
                  },
                ),
                ListTile(
                  title: Text('Fecha Inicio: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Fecha Fin: ${DateFormat('yyyy-MM-dd').format(endDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Estudiantes'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => studentCount = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.post('/api/schedules/', {
                    'environment_id': _environmentId,
                    'instructor_id': Provider.of<AuthProvider>(context, listen: false).currentUser!.id,
                    'program': program,
                    'ficha': ficha,
                    'topic': topic,
                    'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                    'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
                    'day_of_week': dayOfWeek,
                    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                    'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                    'student_count': studentCount,
                  });
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _editSchedule(Map<String, dynamic> schedule) {
    String program = schedule['program'];
    String ficha = schedule['ficha'];
    String topic = schedule['topic'] ?? '';
    TimeOfDay startTime = TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(schedule['start_time']));
    TimeOfDay endTime = TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(schedule['end_time']));
    int dayOfWeek = schedule['day_of_week'];
    DateTime startDate = DateFormat('yyyy-MM-dd').parse(schedule['start_date']);
    DateTime endDate = DateFormat('yyyy-MM-dd').parse(schedule['end_date']);
    int studentCount = schedule['student_count'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Horario'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Programa'),
                  onChanged: (value) => program = value,
                  controller: TextEditingController(text: program),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ficha'),
                  onChanged: (value) => ficha = value,
                  controller: TextEditingController(text: ficha),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Tema'),
                  onChanged: (value) => topic = value,
                  controller: TextEditingController(text: topic),
                ),
                ListTile(
                  title: Text('Inicio: ${startTime.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                      initialEntryMode: TimePickerEntryMode.dial,
                    );
                    if (picked != null) {
                      setState(() {
                        startTime = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Fin: ${endTime.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                      initialEntryMode: TimePickerEntryMode.dial,
                    );
                    if (picked != null) {
                      setState(() {
                        endTime = picked;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text('Día ${i + 1}'))),
                  onChanged: (value) {
                    setState(() {
                      dayOfWeek = value!;
                    });
                  },
                ),
                ListTile(
                  title: Text('Fecha Inicio: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Fecha Fin: ${DateFormat('yyyy-MM-dd').format(endDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Estudiantes'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => studentCount = int.tryParse(value) ?? 0,
                  controller: TextEditingController(text: studentCount.toString()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.put('/api/schedules/${schedule['id']}', {
                    'program': program,
                    'ficha': ficha,
                    'topic': topic,
                    'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                    'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
                    'day_of_week': dayOfWeek,
                    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                    'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                    'student_count': studentCount,
                  });
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

  void _deleteSchedule(String id) async {
    try {
      await _apiService.delete('/api/schedules/$id');
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildStatsTab() {
    final totalEquipment = _calculateTotalItems();
    final available = _calculateAvailableItems();
    final inUse = _calculateInUseItems();
    final damagedMissing = _calculateDamagedMissingItems();
    final maintenance = _inventory.fold(0, (sum, item) {
      if (item['status'] == 'maintenance') {
        return sum + (item['quantity'] as int? ?? 1);
      }
      return sum;
    });
    final completedChecks = _calculateCompletedChecks();
    final totalChecks = _checks.length;

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
          const SizedBox(height: 12),
          _buildStatCard(
            'Dañados/Faltantes',
            damagedMissing.toString(),
            Colors.red,
            Icons.warning,
          ),
          const SizedBox(height: 24),
          const Text(
            'Estadísticas de Verificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Verificaciones Completas',
            '$completedChecks / $totalChecks',
            Colors.green,
            Icons.check,
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
}
