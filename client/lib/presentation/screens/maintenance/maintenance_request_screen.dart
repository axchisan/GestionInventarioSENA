import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  const MaintenanceRequestScreen({super.key});

  @override
  State<MaintenanceRequestScreen> createState() => _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleController = TextEditingController();
  
  late final ApiService _apiService;
  String _selectedType = 'corrective';
  String _selectedPriority = 'medium';
  String _selectedCategory = 'Herramientas';
  bool _isSubmitting = false;
  bool _isItemFromDatabase = false;
  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _apiService = ApiService(authProvider: authProvider);
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user?.environmentId != null) {
        final items = await _apiService.get(
          inventoryEndpoint,
          queryParams: {'environment_id': user!.environmentId.toString()},
        );
        setState(() {
          _inventoryItems = List<Map<String, dynamic>>.from(items);
        });
      }
    } catch (e) {
      debugPrint('Error loading inventory items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Solicitud de Mantenimiento'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Equipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Equipo registrado en inventario'),
                        subtitle: const Text('Seleccionar de equipos existentes'),
                        value: _isItemFromDatabase,
                        onChanged: (value) {
                          setState(() {
                            _isItemFromDatabase = value;
                            _selectedItem = null;
                            _equipmentNameController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información del equipo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Equipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isItemFromDatabase) ...[
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedItem,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Equipo del Inventario',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          items: _inventoryItems.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text('${item['name']} - ${item['internal_code']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedItem = value;
                            });
                          },
                          validator: (value) {
                            if (_isItemFromDatabase && value == null) {
                              return 'Por favor seleccione un equipo del inventario';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _equipmentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Equipo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.build),
                          ),
                          validator: (value) {
                            if (!_isItemFromDatabase && (value == null || value.isEmpty)) {
                              return 'Por favor ingrese el nombre del equipo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoría del Equipo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: [
                            'Herramientas',
                            'Maquinaria',
                            'Equipos de Cómputo',
                            'Mobiliario',
                            'Equipos de Medición',
                            'Otros'
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
                      ],
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación Actual',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la ubicación del equipo';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tipo de mantenimiento
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Mantenimiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Column(
                        children: [
                          _buildMaintenanceTypeCard(
                            'preventive',
                            'Preventivo',
                            'Mantenimiento programado regular',
                            Icons.schedule,
                            AppColors.info,
                          ),
                          const SizedBox(height: 12),
                          _buildMaintenanceTypeCard(
                            'corrective',
                            'Correctivo',
                            'Reparación de fallas o daños',
                            Icons.build,
                            AppColors.warning,
                          ),
                          const SizedBox(height: 12),
                          _buildMaintenanceTypeCard(
                            'emergency',
                            'Emergencia',
                            'Reparación urgente inmediata',
                            Icons.emergency,
                            AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Prioridad y descripción
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Solicitud',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título de la Solicitud',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un título para la solicitud';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: [
                          {'value': 'urgent', 'label': 'Urgente'},
                          {'value': 'high', 'label': 'Alta'},
                          {'value': 'medium', 'label': 'Media'},
                          {'value': 'low', 'label': 'Baja'},
                        ].map((priority) {
                          return DropdownMenuItem(
                            value: priority['value'],
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority['value']!),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(priority['label']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del Problema',
                          border: OutlineInputBorder(),
                          hintText: 'Describe detalladamente el problema o mantenimiento requerido',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor describe el problema o mantenimiento requerido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Información adicional
              Card(
                color: AppColors.info.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppColors.info),
                          SizedBox(width: 8),
                          Text(
                            'Información Importante',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Las solicitudes de emergencia serán atendidas en un máximo de 2 horas\n'
                        '• El mantenimiento preventivo se programa según disponibilidad\n'
                        '• Recibirás notificaciones sobre el estado de tu solicitud\n'
                        '• Para equipos críticos, contacta directamente al área técnica',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enviar Solicitud'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceTypeCard(
    String value,
    String type,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == value;
    
    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : null,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final requestData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'priority': _selectedPriority,
          'maintenance_type': _selectedType,
          'quantity_affected': 1,
        };

        if (_isItemFromDatabase && _selectedItem != null) {
          requestData['item_id'] = _selectedItem!['id'];
        } else {
          requestData['equipment_name'] = _equipmentNameController.text;
          requestData['equipment_location'] = _locationController.text;
          requestData['equipment_category'] = _selectedCategory;
        }

        await _apiService.post('/api/maintenance-requests/', requestData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud de mantenimiento enviada exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar solicitud: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}
