import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  List<dynamic> _pendingChecks = [];
  bool _isLoading = true;
  bool _hasCheckedToday = false;

  // Mapas para traducciones
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
        queryParams: {'environment_id': user.environmentId.toString(), 'date': DateTime.now().toIso8601String().split('T')[0]},
      );
      final pendingChecks = await _apiService.get(
        inventoryChecksEndpoint,
        queryParams: {'environment_id': user.environmentId.toString(), 'status': 'pending'},
      );
      setState(() {
        _items = items;
        _schedules = schedules;
        _hasCheckedToday = checks.isNotEmpty;
        _pendingChecks = pendingChecks;
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

  List<dynamic> get _filteredItems {
    return _items.where((item) {
      final matchesSearch =
          item['name'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
          item['id'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );
      final matchesCategory =
          _selectedCategory == 'Todos' || item['category'] == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'Todos' || item['status'] == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
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
                        if (role == 'student') ...[
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
                                child: Text('${schedule['program']} - ${schedule['start_time']}'),
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
                            'Inventario ya verificado hoy. Puedes actualizar si es necesario.',
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
                              trailing: role == 'instructor' 
                                ? ElevatedButton(
                                    onPressed: () => _confirmCheck(check),
                                    child: const Text('Confirmar'),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _reviewCheck(check),
                                    child: const Text('Revisar'),
                                  ),
                              onTap: () => _showCheckDetails(check),
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
          if (role == 'student') ...[
            FloatingActionButton(
              heroTag: 'check',
              onPressed: _showCheckDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String role) {
    Color statusColor = getStatusColor(item['status']);
    final isGroup = item['item_type'] == 'group';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        isGroup ? 'Grupo: ${item['quantity']} unidades' : 'ID: ${item['id']}',
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
                    onPressed: () => _showItemDetails(item),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalles'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateItemStatus(item),
                    icon: const Icon(Icons.edit),
                    label: const Text('Actualizar Estado'),
                  ),
                ),
              ],
            ),
            if (role == 'supervisor' || role == 'admin') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
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
                      },
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item['id']}'),
            Text('Categoría: ${_categoryTranslations[item['category']] ?? item['category']}'),
            Text('Estado: ${_statusTranslations[item['status']] ?? item['status']}'),
            Text('Cantidad: ${item['quantity'] ?? 1}'),
            Text('Tipo: ${item['item_type'] == 'group' ? 'Grupo' : 'Individual'}'),
            Text('Última Verificación: ${item['updated_at'] ?? 'N/A'}'),
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
                ] else ...[
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
                  final response = await _apiService.post(
                    inventoryChecksEndpoint,
                    {
                      'environment_id': authProvider.currentUser!.environmentId,
                      'schedule_id': _selectedScheduleId,
                      'student_id': authProvider.currentUser!.id,
                      'items': [
                        {
                          'item_id': item['id'],
                          'status': newStatus,
                          'quantity_expected': quantityExpected,
                          'quantity_found': quantityFound,
                          'quantity_damaged': quantityDamaged,
                          'quantity_missing': quantityMissing,
                          'notes': notes,
                        },
                      ],
                      'cleaning_notes': _cleaningNotesController.text,
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Actualizado: ${_statusTranslations[response['status']] ?? response['status']}')),
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
              final itemsList = _items.map((item) {
                final quantity = item['quantity'] ?? 1;
                return {
                  'item_id': item['id'],
                  'status': 'good',
                  'quantity_expected': quantity,
                  'quantity_found': quantity,
                  'quantity_damaged': 0,
                  'quantity_missing': 0,
                  'notes': '',
                };
              }).toList();
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await _apiService.post(
                  inventoryChecksEndpoint,
                  {
                    'environment_id': authProvider.currentUser!.environmentId,
                    'schedule_id': _selectedScheduleId,
                    'student_id': authProvider.currentUser!.id,
                    'items': itemsList,
                    'cleaning_notes': _cleaningNotesController.text,
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verificación masiva completada')),
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

  void _confirmCheck(Map<String, dynamic> check) async {
    bool isClean = true;
    bool isOrganized = true;
    bool inventoryComplete = true;
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Verificación'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Aula aseada'),
                value: isClean,
                onChanged: (value) => setState(() => isClean = value!),
              ),
              CheckboxListTile(
                title: const Text('Sillas y mesas organizadas'),
                value: isOrganized,
                onChanged: (value) => setState(() => isOrganized = value!),
              ),
              CheckboxListTile(
                title: const Text('Inventario completo'),
                value: inventoryComplete,
                onChanged: (value) => setState(() => inventoryComplete = value!),
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
                  const SnackBar(content: Text('Confirmado')),
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

  void _reviewCheck(Map<String, dynamic> check) async {
    String status = 'approved';
    String comments = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar Verificación'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: status,
                items: ['approved', 'rejected'].map((st) {
                  return DropdownMenuItem(value: st, child: Text(_statusTranslations[st] ?? st));
                }).toList(),
                onChanged: (value) => status = value!,
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
                  const SnackBar(content: Text('Revisado')),
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
    );
  }

  void _showCheckDetails(Map<String, dynamic> check) {
    // Implementar diálogo para mostrar detalles completos del check, incluyendo items, comentarios, quién verificó, etc.
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
              Text('Hora: ${check['check_time']}'),
              Text('Estado: ${_statusTranslations[check['status']] ?? check['status']}'),
              Text('Notas de Limpieza: ${check['cleaning_notes'] ?? 'N/A'}'),
              Text('Comentarios: ${check['comments'] ?? 'N/A'}'),
              // Añadir lista de items del check, requeriría fetch adicional si no está en _pendingChecks
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