import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../widgets/common/sena_app_bar.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  final String? preselectedItemId;
  final String? preselectedItemName;
  final String environmentId;

  const MaintenanceRequestScreen({
    super.key,
    this.preselectedItemId,
    this.preselectedItemName,
    required this.environmentId,
  });

  @override
  State<MaintenanceRequestScreen> createState() => _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para solicitud específica
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Controladores para solicitud general
  final _generalDescriptionController = TextEditingController();
  final _generalLocationController = TextEditingController();
  final _itemNameController = TextEditingController();
  
  String _selectedType = 'preventivo';
  String _selectedPriority = 'media';
  String _selectedCategory = 'equipos';
  String? _selectedItemId;
  String? _selectedItemName;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Si hay un item preseleccionado, configurar la primera tab
    if (widget.preselectedItemId != null) {
      _selectedItemId = widget.preselectedItemId;
      _selectedItemName = widget.preselectedItemName;
    } else {
      // Si no hay item preseleccionado, ir a la segunda tab (solicitud general)
      _tabController.index = 1;
    }
    
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await MaintenanceService.getInventoryItems(widget.environmentId);
      setState(() {
        _inventoryItems = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() => _isLoadingItems = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar items: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Solicitud de Mantenimiento'),
      body: Column(
        children: [
          Container(
            color: AppColors.primary.withOpacity(0.1),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey600,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory),
                  text: 'Item Específico',
                ),
                Tab(
                  icon: Icon(Icons.build),
                  text: 'Solicitud General',
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSpecificItemForm(),
                _buildGeneralRequestForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificItemForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selección de item
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar Item del Inventario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoadingItems)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        decoration: const InputDecoration(
                          labelText: 'Item del Inventario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        items: _inventoryItems.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item['name'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Código: ${item['code'] ?? 'N/A'} - Stock: ${item['quantity'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedItemId = value;
                            final selectedItem = _inventoryItems.firstWhere(
                              (item) => item['id'].toString() == value,
                            );
                            _selectedItemName = selectedItem['name'];
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione un item del inventario';
                          }
                          return null;
                        },
                      ),
                    
                    if (_selectedItemId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: AppColors.info, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Item seleccionado: $_selectedItemName',
                                style: const TextStyle(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            _buildMaintenanceTypeSection(),
            const SizedBox(height: 16),
            _buildDetailsSection(isSpecific: true),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información general
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'equipos', child: Text('Equipos')),
                      DropdownMenuItem(value: 'mobiliario', child: Text('Mobiliario')),
                      DropdownMenuItem(value: 'infraestructura', child: Text('Infraestructura')),
                      DropdownMenuItem(value: 'sistemas', child: Text('Sistemas')),
                      DropdownMenuItem(value: 'otros', child: Text('Otros')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre o Descripción del Elemento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                      hintText: 'Ej: Aire acondicionado, Mesa de trabajo, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del elemento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _generalLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación Específica',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Ej: Esquina derecha del aula, junto a la ventana',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor especifique la ubicación';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildMaintenanceTypeSection(),
          const SizedBox(height: 16),
          _buildDetailsSection(isSpecific: false),
          const SizedBox(height: 16),
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTypeSection() {
    return Card(
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
                  'preventivo',
                  'Preventivo',
                  'Mantenimiento programado regular',
                  Icons.schedule,
                  AppColors.info,
                ),
                const SizedBox(height: 12),
                _buildMaintenanceTypeCard(
                  'correctivo',
                  'Correctivo',
                  'Reparación de fallas o daños',
                  Icons.build,
                  AppColors.warning,
                ),
                const SizedBox(height: 12),
                _buildMaintenanceTypeCard(
                  'emergencia',
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
    );
  }

  Widget _buildDetailsSection({required bool isSpecific}) {
    final descriptionController = isSpecific ? _descriptionController : _generalDescriptionController;
    final locationController = isSpecific ? _locationController : _generalLocationController;
    
    return Card(
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
            
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: ['alta', 'media', 'baja'].map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(priority.toUpperCase()),
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
              controller: descriptionController,
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
            const SizedBox(height: 16),
            
            TextFormField(
              controller: locationController,
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
    );
  }

  Widget _buildInfoSection() {
    return Card(
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
      case 'alta':
        return AppColors.error;
      case 'media':
        return AppColors.warning;
      case 'baja':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  void _submitRequest() async {
    final isSpecificTab = _tabController.index == 0;
    
    if (isSpecificTab) {
      if (_formKey.currentState!.validate()) {
        await _performSubmit();
      }
    } else {
      if (_generalDescriptionController.text.isNotEmpty &&
          _generalLocationController.text.isNotEmpty &&
          _itemNameController.text.isNotEmpty) {
        await _performSubmit();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor complete todos los campos requeridos'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _performSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final isSpecificTab = _tabController.index == 0;
      
      final success = await MaintenanceService.createMaintenanceRequest(
        itemId: isSpecificTab ? _selectedItemId : null,
        environmentId: widget.environmentId,
        type: _selectedType,
        priority: _selectedPriority,
        description: isSpecificTab 
            ? _descriptionController.text 
            : _generalDescriptionController.text,
        category: isSpecificTab ? null : _selectedCategory,
        location: isSpecificTab 
            ? _locationController.text 
            : _generalLocationController.text,
        itemName: isSpecificTab ? null : _itemNameController.text,
      );

      if (success) {
        // Crear notificación para supervisores/administradores
        final currentUser = await SessionService.getUser();
        if (currentUser != null) {
          await NotificationService.createVerificationNotification(
            userId: currentUser['id'],
            environmentName: 'Ambiente',
            scheduleTime: 'Solicitud de mantenimiento',
            type: 'maintenance_update',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud de mantenimiento enviada exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        }
      } else {
        throw Exception('Error al enviar la solicitud');
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _generalDescriptionController.dispose();
    _generalLocationController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }
}