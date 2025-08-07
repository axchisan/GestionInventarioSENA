import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';

class InventoryCheckScreen extends StatefulWidget {
  const InventoryCheckScreen({super.key});

  @override
  State<InventoryCheckScreen> createState() => _InventoryCheckScreenState();
}

class _InventoryCheckScreenState extends State<InventoryCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';
  String _selectedStatus = 'Todos';

  final List<Map<String, dynamic>> _mockItems = [
    {
      'id': 'SENA-001',
      'name': 'Laptop Dell Inspiron 15',
      'category': 'Equipos de Cómputo',
      'status': 'Disponible',
      'location': 'Aula 101',
      'lastCheck': '2024-01-15',
      'condition': 'Excelente',
    },
    {
      'id': 'SENA-002',
      'name': 'Proyector Epson',
      'category': 'Audiovisuales',
      'status': 'En Préstamo',
      'location': 'Aula 205',
      'lastCheck': '2024-01-14',
      'condition': 'Bueno',
    },
    {
      'id': 'SENA-003',
      'name': 'Taladro Industrial',
      'category': 'Herramientas',
      'status': 'Mantenimiento',
      'location': 'Taller A',
      'lastCheck': '2024-01-10',
      'condition': 'Regular',
    },
    {
      'id': 'SENA-004',
      'name': 'Microscopio Óptico',
      'category': 'Laboratorio',
      'status': 'Disponible',
      'location': 'Lab. Ciencias',
      'lastCheck': '2024-01-16',
      'condition': 'Excelente',
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _mockItems.where((item) {
      final matchesSearch = item['name']
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()) ||
          item['id']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'Todos' || 
          item['category'] == _selectedCategory;
      
      final matchesStatus = _selectedStatus == 'Todos' || 
          item['status'] == _selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Verificación de Inventario'),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.grey100,
            child: Column(
              children: [
                // Barra de búsqueda
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
                
                // Filtros por categoría y estado
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
                          'Equipos de Cómputo',
                          'Audiovisuales',
                          'Herramientas',
                          'Laboratorio',
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
                          'Disponible',
                          'En Préstamo',
                          'Mantenimiento',
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
          
          // Lista de items
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
        onPressed: () {
          _showAddItemDialog(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    Color statusColor;
    switch (item['status']) {
      case 'Disponible':
        statusColor = AppColors.success;
        break;
      case 'En Préstamo':
        statusColor = AppColors.warning;
        break;
      case 'Mantenimiento':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey500;
    }

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
                      const SizedBox(height: 4),
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
                    item['location'],
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
                    item['lastCheck'],
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.star,
                    'Condición',
                    item['condition'],
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
            Text('Ubicación: ${item['location']}'),
            Text('Última Verificación: ${item['lastCheck']}'),
            Text('Condición: ${item['condition']}'),
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
    // Implementar actualización de estado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de ${item['name']} actualizado'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nuevo Item'),
        content: const Text('Funcionalidad para agregar nuevos items al inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
