import 'package:flutter/material.dart';
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
  final ApiService _apiService = ApiService();
  String _selectedCategory = 'Todos';
  String _selectedStatus = 'Todos';
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user?.environmentId != null) {
      try {
        final items = await _apiService.get(
          inventoryEndpoint,
          queryParams: {'environment_id': ?user!.environmentId},
        );
        setState(() {
          _items = items;
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar inventario: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincula un ambiente para verificar el inventario')),
      );
    }
  }

  List<dynamic> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item['name']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          item['id']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todos' || item['category'] == _selectedCategory;
      final matchesStatus = _selectedStatus == 'Todos' || item['status'] == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Verificación de Inventario'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                'computer',
                                'projector',
                                'keyboard',
                                'mouse',
                                'tv',
                                'camera',
                                'microphone',
                                'tablet',
                                'other',
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
                                'available',
                                'in_use',
                                'maintenance',
                                'damaged',
                                'lost',
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
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildItemCard(item);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCheckDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    Color statusColor = getStatusColor(item['status']);
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
                        'ID: ${item['id']}',
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item['status'],
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
                    item['category'],
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
                    item['status'],
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
                    label: const Text('Actualizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'in_use':
        return AppColors.warning;
      case 'maintenance':
        return AppColors.error;
      case 'damaged':
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey600,
                ),
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
            Text('Categoría: ${item['category']}'),
            Text('Estado: ${item['status']}'),
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

  void _updateItemStatus(Map<String, dynamic> item) async {
    // Mostrar diálogo para actualizar el estado
    String? newStatus;
    int quantityFound = item['quantity'] ?? 1;
    int quantityDamaged = 0;
    int quantityMissing = 0;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                value: item['status'],
                items: ['good', 'damaged', 'missing'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  newStatus = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad Encontrada',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  quantityFound = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad Dañada',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  quantityDamaged = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad Faltante',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  quantityMissing = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
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
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final response = await _apiService.post(
                  '/api/inventory-checks',
                  {
                    'environment_id': authProvider.currentUser!.environmentId,
                    'student_id': authProvider.currentUser!.id, // O instructor_id según el rol
                    'items': [
                      {
                        'item_id': item['id'],
                        'status': newStatus ?? item['status'],
                        'quantity_expected': item['quantity'] ?? 1,
                        'quantity_found': quantityFound,
                        'quantity_damaged': quantityDamaged,
                        'quantity_missing': quantityMissing,
                        'notes': notes,
                      }
                    ],
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estado actualizado: ${response['status']}')),
                );
                Navigator.pop(context);
                _fetchItems(); // Refrescar la lista
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showCheckDialog() {
    // Implementar diálogo para verificación masiva si es necesario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de verificación masiva en desarrollo')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }
}