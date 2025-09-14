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
import 'package:http/http.dart' as http;

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
  // ignore: unused_field
  List<dynamic> _scheduleStats = [];
  // ignore: unused_field
  bool _showScheduleDetails = false;
  List<dynamic> _items = [];
  List<dynamic> _schedules = [];
  List<dynamic> _checks = [];
  List<dynamic> _pendingChecks = [];
  // ignore: unused_field
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

  bool _isClean = false;
  bool _isOrganized = false;
  bool _inventoryComplete = false;
  String _cleaningNotes = '';
  String _comments = '';

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

  String _determineItemStatus(int quantityFound, int quantityDamaged, int quantityMissing) {
    // If there are damaged items, prioritize maintenance status
    if (quantityDamaged > 0) {
      return 'maintenance';
    }
    
    // If there are missing items, mark as missing
    if (quantityMissing > 0) {
      return 'missing';
    }
    
    // If all items are found and none are damaged or missing, mark as available
    if (quantityFound > 0 && quantityDamaged == 0 && quantityMissing == 0) {
      return 'available';
    }
    
    // Default case - if no items found at all
    return 'missing';
  }

  int _calculateTotalEnvironmentItems() {
    return _items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  int _calculateDamagedEnvironmentItems() {
    return _items.fold(0, (sum, item) {
      final damagedQuantity = item['quantity_damaged'] as int? ?? 0;
      return sum + damagedQuantity;
    });
  }

  int _calculateMissingEnvironmentItems() {
    return _items.fold(0, (sum, item) {
      final missingQuantity = item['quantity_missing'] as int? ?? 0;
      return sum + missingQuantity;
    });
  }

  int _calculateAvailableEnvironmentItems() {
    return _items.fold(0, (sum, item) {
      final totalQuantity = item['quantity'] as int? ?? 1;
      final damagedQuantity = item['quantity_damaged'] as int? ?? 0;
      final missingQuantity = item['quantity_missing'] as int? ?? 0;
      final availableQuantity = totalQuantity - damagedQuantity - missingQuantity;
      return sum + availableQuantity;
    });
  }

  
  Color getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'instructor_review':
        return AppColors.warning;
      case 'supervisor_review':
        return AppColors.info;
      case 'pending':
        return AppColors.secondary;
      case 'available':
      case 'good':
        return AppColors.success;
      case 'damaged':
        return AppColors.error;
      case 'missing':
      case 'lost':
        return AppColors.error;
      case 'in_use':
        return AppColors.info;
      case 'maintenance':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  void _showCheckDetails(Map<String, dynamic> check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Verificación #${check['id'].toString().substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      'Información General',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Estado', _statusTranslations[check['status']] ?? check['status']),
                    _buildDetailRow('Fecha', check['check_date'] ?? 'N/A'),
                    if (check['check_time'] != null)
                      _buildDetailRow('Hora', _formatColombianTime(check['check_time'])),
                    if (check['environment_id'] != null)
                      _buildDetailRow('Ambiente ID', check['environment_id'].toString().substring(0, 8)),
                    if (check['schedule_id'] != null)
                      _buildDetailRow('Horario ID', check['schedule_id'].toString().substring(0, 8)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Participants information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participantes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (check['student_id'] != null)
                      _buildDetailRow('Estudiante ID', check['student_id'].toString().substring(0, 8)),
                    if (check['instructor_id'] != null)
                      _buildDetailRow('Instructor ID', check['instructor_id'].toString().substring(0, 8)),
                    if (check['supervisor_id'] != null)
                      _buildDetailRow('Supervisor ID', check['supervisor_id'].toString().substring(0, 8)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Inventory statistics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estadísticas de Inventario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Total Items', (check['total_items'] ?? 0).toString()),
                    _buildDetailRow('Items Buenos', (check['items_good'] ?? 0).toString()),
                    _buildDetailRow('Items Dañados', (check['items_damaged'] ?? 0).toString()),
                    _buildDetailRow('Items Faltantes', (check['items_missing'] ?? 0).toString()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Verification status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Verificación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (check['is_clean'] != null)
                      _buildDetailRow('Aula Limpia', check['is_clean'] ? 'Sí' : 'No'),
                    if (check['is_organized'] != null)
                      _buildDetailRow('Aula Organizada', check['is_organized'] ? 'Sí' : 'No'),
                    if (check['inventory_complete'] != null)
                      _buildDetailRow('Inventario Completo', check['inventory_complete'] ? 'Sí' : 'No'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Comments and notes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentarios y Notas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (check['cleaning_notes'] != null && check['cleaning_notes'].toString().isNotEmpty)
                      _buildDetailRow('Notas de Limpieza', check['cleaning_notes']),
                    if (check['comments'] != null && check['comments'].toString().isNotEmpty)
                      _buildDetailRow('Comentarios Generales', check['comments']),
                    if (check['instructor_comments'] != null && check['instructor_comments'].toString().isNotEmpty)
                      _buildDetailRow('Comentarios del Instructor', check['instructor_comments']),
                    if (check['supervisor_comments'] != null && check['supervisor_comments'].toString().isNotEmpty)
                      _buildDetailRow('Comentarios del Supervisor', check['supervisor_comments']),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Timestamps
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de Confirmaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (check['student_confirmed_at'] != null)
                      _buildDetailRow('Confirmado por Estudiante', _formatDateTime(check['student_confirmed_at'])),
                    if (check['instructor_confirmed_at'] != null)
                      _buildDetailRow('Confirmado por Instructor', _formatDateTime(check['instructor_confirmed_at'])),
                    if (check['supervisor_confirmed_at'] != null)
                      _buildDetailRow('Confirmado por Supervisor', _formatDateTime(check['supervisor_confirmed_at'])),
                    if (check['created_at'] != null)
                      _buildDetailRow('Creado', _formatDateTime(check['created_at'])),
                    if (check['updated_at'] != null)
                      _buildDetailRow('Última Actualización', _formatDateTime(check['updated_at'])),
                  ],
                ),
              ),
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return dateTime.toString();
      }
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getItemCheckData(String itemId) {
    // Return check data for specific item if available
    return null; // Placeholder - implement based on your data structure
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] ?? 'Detalles del Item'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      'Información Básica',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Nombre', item['name'] ?? 'N/A'),
                    _buildDetailRow('Código Interno', item['internal_code'] ?? item['code'] ?? item['id'] ?? 'N/A'),
                    if (item['serial_number'] != null && item['serial_number'].toString().isNotEmpty)
                      _buildDetailRow('Número de Serie', item['serial_number']),
                    _buildDetailRow('Categoría', _categoryTranslations[item['category']] ?? item['category'] ?? 'N/A'),
                    _buildDetailRow('Tipo', item['item_type'] == 'group' ? 'Grupo' : 'Individual'),
                    _buildDetailRow('Estado', _statusTranslations[item['status']] ?? item['status'] ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Quantity information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Cantidades',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Cantidad Total', item['quantity']?.toString() ?? '1'),
                    if (item['quantity_damaged'] != null && item['quantity_damaged'] > 0)
                      _buildDetailRow('Cantidad Dañada', item['quantity_damaged'].toString()),
                    if (item['quantity_missing'] != null && item['quantity_missing'] > 0)
                      _buildDetailRow('Cantidad Faltante', item['quantity_missing'].toString()),
                    if (item['quantity_expected'] != null)
                      _buildDetailRow('Cantidad Esperada', item['quantity_expected'].toString()),
                    if (item['quantity_found'] != null)
                      _buildDetailRow('Cantidad Encontrada', item['quantity_found'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Additional details
              if (item['brand'] != null || item['model'] != null || item['description'] != null || item['notes'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles Adicionales',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item['brand'] != null && item['brand'].toString().isNotEmpty)
                        _buildDetailRow('Marca', item['brand']),
                      if (item['model'] != null && item['model'].toString().isNotEmpty)
                        _buildDetailRow('Modelo', item['model']),
                      if (item['description'] != null && item['description'].toString().isNotEmpty)
                        _buildDetailRow('Descripción', item['description']),
                      if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                        _buildDetailRow('Notas', item['notes']),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              
              // Dates information
              if (item['purchase_date'] != null || item['warranty_expiry'] != null || 
                  item['last_maintenance'] != null || item['next_maintenance'] != null ||
                  item['created_at'] != null || item['updated_at'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fechas Importantes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item['purchase_date'] != null)
                        _buildDetailRow('Fecha de Compra', _formatDate(item['purchase_date'])),
                      if (item['warranty_expiry'] != null)
                        _buildDetailRow('Vencimiento Garantía', _formatDate(item['warranty_expiry'])),
                      if (item['last_maintenance'] != null)
                        _buildDetailRow('Último Mantenimiento', _formatDate(item['last_maintenance'])),
                      if (item['next_maintenance'] != null)
                        _buildDetailRow('Próximo Mantenimiento', _formatDate(item['next_maintenance'])),
                      if (item['created_at'] != null)
                        _buildDetailRow('Creado', _formatDateTime(item['created_at'])),
                      if (item['updated_at'] != null)
                        _buildDetailRow('Actualizado', _formatDateTime(item['updated_at'])),
                    ],
                  ),
                ),
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dt;
      if (date is String) {
        dt = DateTime.parse(date);
      } else if (date is DateTime) {
        dt = date;
      } else {
        return date.toString();
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'electronics':
        return Icons.electrical_services;
      case 'furniture':
        return Icons.chair;
      case 'tools':
        return Icons.build;
      case 'computers':
        return Icons.computer;
      case 'laboratory':
        return Icons.science;
      case 'office':
        return Icons.business;
      default:
        return Icons.inventory;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String? value) {
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey600,
                ),
              ),
              Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckDataSection(Map<String, dynamic> checkData, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de Verificación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // Add check data display based on your data structure
          Text(
            'Última verificación: ${checkData['last_check'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _editItemDialog(Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item['name']);
    final descriptionController = TextEditingController(text: item['description']);
    final quantityController = TextEditingController(text: item['quantity']?.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              // Implement item update logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item actualizado exitosamente')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Item'),
        content: Text('¿Estás seguro de que deseas eliminar "${item['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement item deletion logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item eliminado exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCheck() async {
    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un turno/horario primero')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final environmentId = authProvider.currentUser?.environmentId ?? '';
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inventory-checks/by-schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'environment_id': environmentId,
          'schedule_id': _selectedScheduleId,
          'is_clean': _isClean,
          'is_organized': _isOrganized,
          'inventory_complete': _inventoryComplete,
          'cleaning_notes': _cleaningNotes,
          'comments': _comments,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verificación guardada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
        _fetchScheduleCheck();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error: ${response.statusCode} - ${errorData.toString()}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar verificación: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estadísticas del Ambiente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactStatChip(
                                        'Total',
                                        '${_calculateTotalEnvironmentItems()}',
                                        AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildCompactStatChip(
                                        'Disponibles',
                                        '${_calculateAvailableEnvironmentItems()}',
                                        AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildCompactStatChip(
                                        'Dañados',
                                        '${_calculateDamagedEnvironmentItems()}',
                                        AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildCompactStatChip(
                                        'Faltantes',
                                        '${_calculateMissingEnvironmentItems()}',
                                        AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedScheduleId,
                                  decoration: InputDecoration(
                                    labelText: 'Turno/Horario',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: _schedules.map((schedule) {
                                    return DropdownMenuItem(
                                      value: schedule['id'].toString(),
                                      child: Text(
                                        '${schedule['program']} - ${schedule['ficha']} (${_formatColombianTime(schedule['start_time'])} - ${_formatColombianTime(schedule['end_time'])})',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildCompactScheduleInfo(
                                            Icons.people,
                                            'Estudiantes: ${_selectedSchedule!['student_count']}',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildCompactScheduleInfo(
                                            Icons.access_time,
                                            'Duración: ${_calculateDuration(_selectedSchedule!['start_time'], _selectedSchedule!['end_time'])}',
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
                  Text(
                    'Verificaciones Pendientes (${_pendingChecks.length})',
                    style: const TextStyle(
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
                  Text(
                    'Historial de Verificaciones (${_checks.length})',
                    style: const TextStyle(
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
                        Text('Cantidad esperada: $quantityExpected'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Encontrados',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: quantityFound.toString(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    quantityFound = int.tryParse(value) ?? 0;
                                    _validateQuantities(quantityExpected, quantityFound, quantityDamaged, quantityMissing, setDialogState);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Dañados',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: quantityDamaged.toString(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    quantityDamaged = int.tryParse(value) ?? 0;
                                    _validateQuantities(quantityExpected, quantityFound, quantityDamaged, quantityMissing, setDialogState);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Faltantes',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: quantityMissing.toString(),
                          onChanged: (value) {
                            setDialogState(() {
                              quantityMissing = int.tryParse(value) ?? 0;
                              _validateQuantities(quantityExpected, quantityFound, quantityDamaged, quantityMissing, setDialogState);
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getQuantityValidationColor(quantityExpected, quantityFound, quantityDamaged, quantityMissing),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getQuantityValidationMessage(quantityExpected, quantityFound, quantityDamaged, quantityMissing),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
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
                          'Estado del Item',
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
                ],
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value,
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
                  final total = quantityFound + quantityDamaged + quantityMissing;
                  if (total != quantityExpected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('La suma debe ser igual a $quantityExpected (actual: $total)'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                }
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  // Create InventoryCheckItem
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
                  
                  await _apiService.put(
                    '/api/inventory/${item['id']}/verification',
                    {
                      'quantity': quantityFound,
                      'quantity_damaged': quantityDamaged,
                      'quantity_missing': quantityMissing,
                      'status': _determineItemStatus(quantityFound, quantityDamaged, quantityMissing),
                    },
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item actualizado correctamente'),
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
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _validateQuantities(int expected, int found, int damaged, int missing, StateSetter setDialogState) {
    // Auto-adjust if total exceeds expected
    final total = found + damaged + missing;
    if (total > expected) {
      final excess = total - expected;
      if (missing >= excess) {
        missing -= excess;
      } else if (damaged >= excess) {
        damaged -= excess;
      } else {
        found -= excess;
      }
      setDialogState(() {});
    }
  }

  Color _getQuantityValidationColor(int expected, int found, int damaged, int missing) {
    final total = found + damaged + missing;
    if (total == expected) {
      return AppColors.success;
    } else if (total < expected) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getQuantityValidationMessage(int expected, int found, int damaged, int missing) {
    final total = found + damaged + missing;
    if (total == expected) {
      return 'Cantidades correctas ✓';
    } else if (total < expected) {
      return 'Faltan ${expected - total} items por contabilizar';
    } else {
      return 'Exceso de ${total - expected} items';
    }
  }

  void _showCheckDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUser?.role ?? '';
    
    if (role == 'supervisor') {
      _showSupervisorCheckDialog();
    } else {
      _showBasicCheckDialog();
    }
  }

  void _showBasicCheckDialog() {
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
                          _saveCheck();
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
                          _saveCheck();
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
              _saveCheck();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSupervisorCheckDialog() {
    bool? isClean;
    bool? isOrganized;
    bool? inventoryComplete;
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Verificación Completa de Supervisor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.supervisor_account, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Verificación de Supervisor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Como supervisor, puede completar todas las etapas de verificación en una sola sesión.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aspectos a verificar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Marque solo los aspectos que se encuentren en buen estado:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Aula aseada'),
                  subtitle: const Text('El ambiente se encuentra limpio'),
                  value: isClean ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      isClean = value;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Aula organizada'),
                  subtitle: const Text('Los elementos están en su lugar'),
                  value: isOrganized ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      isOrganized = value;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Inventario completo'),
                  subtitle: const Text('Todos los items están presentes'),
                  value: inventoryComplete ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      inventoryComplete = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Comentarios de supervisión',
                    hintText: 'Observaciones generales sobre la verificación...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => comments = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cleaningNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas de limpieza (opcional)',
                    hintText: 'Detalles específicos sobre el estado del ambiente...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                  await _saveSupervisorCompleteCheck(
                    isClean: isClean ?? false,
                    isOrganized: isOrganized ?? false,
                    inventoryComplete: inventoryComplete ?? false,
                    comments: comments,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verificación completa guardada exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar verificación: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Completar Verificación'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSupervisorCompleteCheck({
    required bool isClean,
    required bool isOrganized,
    required bool inventoryComplete,
    required String comments,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    if (_selectedScheduleId == null) {
      throw Exception('Debe seleccionar un horario para realizar la verificación');
    }

    try {
      // Use the by-schedule endpoint that allows supervisor to complete all stages
      final checkData = {
        'environment_id': user.environmentId,
        'schedule_id': _selectedScheduleId,
        'is_clean': isClean,
        'is_organized': isOrganized,
        'inventory_complete': inventoryComplete,
        'comments': comments,
        'cleaning_notes': _cleaningNotesController.text,
      };

      await _apiService.post('/api/inventory-checks/by-schedule', checkData);
    } catch (e) {
      throw Exception('Error al guardar verificación: $e');
    }
  }

  void _confirmInstructorCheck(Map<String, dynamic> check) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUser?.role ?? '';
    
    bool? isClean;
    bool? isOrganized;
    bool? inventoryComplete;
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(role == 'supervisor' ? 'Confirmación de Supervisor' : 'Confirmación de Instructor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role == 'supervisor') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.supervisor_account, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Revisión de Supervisor',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Puede completar la verificación del instructor si no se ha realizado.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Por favor confirme los siguientes aspectos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Marque solo los aspectos que se encuentren en buen estado:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Aula aseada'),
                  value: isClean ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      isClean = value;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Aula organizada'),
                  value: isOrganized ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      isOrganized = value;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Inventario completo'),
                  value: inventoryComplete ?? false,
                  onChanged: (value) {
                    setDialogState(() {
                      inventoryComplete = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: role == 'supervisor' ? 'Comentarios de supervisión' : 'Comentarios adicionales',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => comments = value,
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
                  await _apiService.put('/api/inventory-checks/${check['id']}/confirm', {
                    'is_clean': isClean ?? false,
                    'is_organized': isOrganized ?? false,
                    'inventory_complete': inventoryComplete ?? false,
                    'comments': comments,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verificación confirmada por ${role == 'supervisor' ? 'supervisor' : 'instructor'}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _fetchData();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _reviewSupervisorCheck(Map<String, dynamic> check) async {
    bool approved = true;
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Revisión Final de Supervisor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de la Verificación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Items: ${check['total_items'] ?? 0}'),
                      Text('Items Buenos: ${check['items_good'] ?? 0}'),
                      Text('Items Dañados: ${check['items_damaged'] ?? 0}'),
                      Text('Items Faltantes: ${check['items_missing'] ?? 0}'),
                      if (check['is_clean'] != null)
                        Text('Aula Limpia: ${check['is_clean'] ? 'Sí' : 'No'}'),
                      if (check['is_organized'] != null)
                        Text('Aula Organizada: ${check['is_organized'] ? 'Sí' : 'No'}'),
                      if (check['inventory_complete'] != null)
                        Text('Inventario Completo: ${check['inventory_complete'] ? 'Sí' : 'No'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Decisión de Supervisión:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RadioListTile<bool>(
                  title: const Text('Aprobar Verificación'),
                  subtitle: const Text('La verificación cumple con los estándares'),
                  value: true,
                  groupValue: approved,
                  onChanged: (value) {
                    setDialogState(() {
                      approved = value ?? true;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Rechazar Verificación'),
                  subtitle: const Text('La verificación requiere correcciones'),
                  value: false,
                  groupValue: approved,
                  onChanged: (value) {
                    setDialogState(() {
                      approved = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Comentarios de supervisión',
                    hintText: 'Observaciones sobre la verificación...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => comments = value,
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
                  await _apiService.put('/api/inventory-checks/${check['id']}/supervisor-approve', {
                    'approved': approved,
                    'comments': comments,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verificación ${approved ? 'aprobada' : 'rechazada'} por supervisor'),
                      backgroundColor: approved ? AppColors.success : AppColors.warning,
                    ),
                  );
                  _fetchData();
                  Navigator.pop(context);
                  Navigator.pop(context);
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

  Widget _buildCompactStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactScheduleInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
