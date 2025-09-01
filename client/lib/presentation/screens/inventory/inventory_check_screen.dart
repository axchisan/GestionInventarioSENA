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
  List<dynamic> _notifications = []; // Nueva: Para notificaciones
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
    // ignore: equal_keys_in_map
    'damaged': 'Dañado',
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
        queryParams: {'environment_id': user.environmentId.toString()},
      );
      final notifications = await _apiService.get(
        '/api/notifications/', // Nuevo endpoint para notificaciones del user
      );
      final pendingChecks = checks.where((check) => ['pending', 'instructor_review', 'supervisor_review'].contains(check['status'])).toList();
      final todayCheck = checks.firstWhere(
        (check) => check['check_date'] == DateTime.now().toIso8601String().split('T')[0],
        orElse: () => null,
      );
      // ignore: unused_element
      setState() {
        _items = items;
        _schedules = schedules;
        _checks = checks;
        _pendingChecks = pendingChecks;
        _notifications = notifications;
        _hasCheckedToday = todayCheck != null;
        _isLoading = false;
      };
    } catch (e) {
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
      final dateTime = DateFormat('HH:mm').parse(timeStr); // Parsea 24h
      return _colombianTimeFormat.format(dateTime); // Formato 12h AM/PM
    } catch (e) {
      return timeStr; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentUser?.role ?? '';

    return Scaffold(
      appBar: const SenaAppBar(title: 'Verificación de Inventario'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: AppColors.grey100,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
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
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                  border: OutlineInputBorder(),
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
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
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
                          DropdownButtonFormField<String>(
                            value: _selectedScheduleId,
                            decoration: const InputDecoration(
                              labelText: 'Turno/Horario',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _schedules.map((schedule) {
                              return DropdownMenuItem(
                                value: schedule['id'].toString(),
                                child: Text('${schedule['program']} - ${_formatColombianTime(schedule['start_time'])} - ${_formatColombianTime(schedule['end_time'])}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedScheduleId = value;
                              });
                            },
                          ),
                        ],
                        if (_hasCheckedToday) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Inventario ya verificado hoy. Puedes ver historial o actualizar individualmente.',
                            style: TextStyle(color: AppColors.success),
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
                        return _buildItemCard(item, role);
                      },
                    ),
                  ),
                  if (role == 'instructor' || role == 'supervisor') ...[
                    const SizedBox(height: 16),
                    const Text('Verificaciones Pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pendingChecks.length,
                        itemBuilder: (context, index) {
                          final check = _pendingChecks[index];
                          return Card(
                            child: ListTile(
                              title: Text('Check ID: ${check['id']}'),
                              subtitle: Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                              trailing: role == 'instructor' && check['status'] == 'instructor_review'
                                  ? ElevatedButton(
                                      onPressed: () => _confirmInstructorCheck(check),
                                      child: const Text('Confirmar'),
                                    )
                                  : role == 'supervisor' && check['status'] == 'supervisor_review'
                                      ? ElevatedButton(
                                          onPressed: () => _reviewSupervisorCheck(check),
                                          child: const Text('Revisar'),
                                        )
                                      : null,
                              onTap: () => _showCheckDetails(check),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_hasCheckedToday || _checks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Historial de Verificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _checks.length,
                        itemBuilder: (context, index) {
                          final check = _checks[index];
                          return Card(
                            child: ListTile(
                              title: Text('Check ID: ${check['id']} - ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
                              subtitle: Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
                              onTap: () => _showCheckDetails(check),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Nueva sección para notificaciones
                  if (_notifications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return Card(
                            child: ListTile(
                              title: Text(notif['title']),
                              subtitle: Text(notif['message']),
                              trailing: notif['is_read'] ? Icon(Icons.check) : Icon(Icons.notifications_active),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                context.push('/add-inventory-item', extra: {'environmentId': authProvider.currentUser?.environmentId});
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
          if ((role == 'student' || role == 'instructor' || role == 'supervisor') && !_hasCheckedToday) ...[
            FloatingActionButton(
              heroTag: 'check',
              onPressed: _showCheckDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'report',
            onPressed: _showReportDamageDialog,
            backgroundColor: AppColors.error,
            child: const Icon(Icons.report_problem, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String role) {
    Color statusColor = getStatusColor(item['status']);
    final isGroup = item['item_type'] == 'group';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showItemDetails(item),
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
                        Text(
                          isGroup ? 'Grupo: Encontrados ${item['quantity'] - (item['quantity_damaged'] ?? 0) - (item['quantity_missing'] ?? 0)}, Dañados ${item['quantity_damaged'] ?? 0}, Faltantes ${item['quantity_missing'] ?? 0}' : 'ID: ${item['id']}',
                          style: const TextStyle(
                            color: AppColors.grey600,
                            fontFamily: 'monospace',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateItemStatus(item),
                      icon: const Icon(Icons.edit),
                      label: const Text('Actualizar Estado'),
                    ),
                  ),
                  if (role == 'supervisor' || role == 'admin') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editItemDialog(item), // Nueva: Edición en dialog
                        icon: const Icon(Icons.edit_document),
                        label: const Text('Editar Item'),
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
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isGroup) ...[
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text('Encontrados: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityFound > 0) quantityFound--;
                              });
                            },
                          ),
                          Text(quantityFound.toString()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) quantityFound++;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Dañados: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityDamaged > 0) quantityDamaged--;
                              });
                            },
                          ),
                          Text(quantityDamaged.toString()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) quantityDamaged++;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Faltantes: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityMissing > 0) quantityMissing--;
                              });
                            },
                          ),
                          Text(quantityMissing.toString()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setDialogState(() {
                                if (quantityFound + quantityDamaged + quantityMissing < quantityExpected) quantityMissing++;
                              });
                            },
                          ),
                        ],
                      ),
                      Text('Total esperado: $quantityExpected'),
                      Text('Total reportado: ${quantityFound + quantityDamaged + quantityMissing}'),
                    ],
                  ),
                ],
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
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
                    const SnackBar(content: Text('Las cantidades deben sumar el esperado')),
                  );
                  return;
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
                  // Actualiza InventoryItem con quantity y status
                  String updatedStatus = newStatus;
                  if (quantityMissing > 0) updatedStatus = 'lost';
                  else if (quantityDamaged > 0) updatedStatus = 'damaged';
                  await _apiService.put(
                    '$inventoryEndpoint${item['id']}',
                    {
                      'quantity': quantityFound + quantityDamaged,
                      'status': updatedStatus,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item actualizado: ${_statusTranslations[newStatus] ?? newStatus}')),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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

  void _showCheckDialog() {
    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un horario')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificación Masiva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Marcar todo como en orden hoy?'),
            const SizedBox(height: 16),
            TextField(
              controller: _cleaningNotesController,
              decoration: const InputDecoration(
                labelText: 'Notas de Aseo/Basura',
                border: OutlineInputBorder(),
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
                await _apiService.post(
                  inventoryChecksEndpoint,
                  {
                    'environment_id': authProvider.currentUser!.environmentId,
                    'schedule_id': _selectedScheduleId,
                    'student_id': authProvider.currentUser!.id,
                    'cleaning_notes': _cleaningNotesController.text,
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verificación masiva completada. Estado: instructor_review')),
                );
                Navigator.pop(context);
                _fetchData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showReportDamageDialog() {
    String description = '';
    String priority = 'medium';
    String itemId = ''; // Asumir selección, o pasar desde item si en context
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Daño/Faltante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Descripción'),
              onChanged: (value) => description = value,
            ),
            DropdownButtonFormField<String>(
              value: priority,
              items: ['low', 'medium', 'high', 'urgent'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) => priority = value!,
              decoration: const InputDecoration(labelText: 'Prioridad'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'ID del Item'),
              onChanged: (value) => itemId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.post('/api/maintenance-requests/', {
                  'item_id': itemId,
                  'title': 'Daño reportado',
                  'description': description,
                  'priority': priority,
                  'user_id': Provider.of<AuthProvider>(context, listen: false).currentUser!.id,
                });
                Navigator.pop(context);
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _confirmInstructorCheck(Map<String, dynamic> check) async {
    bool isClean = true;
    bool isOrganized = true;
    bool inventoryComplete = true;
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirmar Verificación (Instructor)'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Aula aseada'),
                  value: isClean,
                  onChanged: (value) => setDialogState(() => isClean = value!),
                ),
                CheckboxListTile(
                  title: const Text('Sillas y mesas organizadas'),
                  value: isOrganized,
                  onChanged: (value) => setDialogState(() => isOrganized = value!),
                ),
                CheckboxListTile(
                  title: const Text('Inventario completo'),
                  value: inventoryComplete,
                  onChanged: (value) => setDialogState(() => inventoryComplete = value!),
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
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
                  await _apiService.put(
                    '$inventoryChecksEndpoint${check['id']}/confirm',
                    {
                      'is_clean': isClean,
                      'is_organized': isOrganized,
                      'inventory_complete': inventoryComplete,
                      'comments': comments,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmado por Instructor. Estado: supervisor_review')),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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
    String status = 'approved';
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Revisar Verificación (Supervisor)'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['approved', 'rejected'].map((st) {
                    return DropdownMenuItem(value: st, child: Text(_statusTranslations[st] ?? st));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Comentarios',
                    border: OutlineInputBorder(),
                  ),
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
                  await _apiService.post(
                    '/api/supervisor-reviews/',
                    {
                      'check_id': check['id'],
                      'status': status,
                      'comments': comments,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Revisado por Supervisor. Estado: complete o issues')),
                  );
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Enviar'),
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
        title: const Text('Detalles de Verificación'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${check['id']}'),
              Text('Fecha: ${check['check_date']}'),
              Text('Hora: ${_formatColombianTime(check['check_time'] ?? '00:00:00')}'),
              Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
              Text('Notas de Limpieza: ${check['cleaning_notes'] ?? 'N/A'}'),
              Text('Comentarios: ${check['comments'] ?? 'N/A'}'),
              Text('Aseada: ${check['is_clean'] == true ? 'Sí' : check['is_clean'] == false ? 'No' : 'Pendiente'}'),
              Text('Organizada: ${check['is_organized'] == true ? 'Sí' : check['is_organized'] == false ? 'No' : 'Pendiente'}'),
              Text('Inventario Completo: ${check['inventory_complete'] == true ? 'Sí' : check['inventory_complete'] == false ? 'No' : 'Pendiente'}'),
              const SizedBox(height: 8),
              const Text('Items:'),
              ...(check['items'] ?? []).map((item) => Text('${item['item_id']}: ${_statusTranslations[item['status']]} (Encontrados: ${item['quantity_found'] ?? 0}, Dañados: ${item['quantity_damaged'] ?? 0}, Faltantes: ${item['quantity_missing'] ?? 0})')),
              if ((check['supervisor_reviews'] ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Revisión Supervisor:'),
                Text('Estado: ${_statusTranslations[check['supervisor_reviews'][0]['status']]}'),
                Text('Comentarios: ${check['supervisor_reviews'][0]['comments'] ?? 'N/A'}'),
              ],
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

  @override
  void dispose() {
    _searchController.dispose();
    _cleaningNotesController.dispose();
    _apiService.dispose();
    super.dispose();
  }
}