import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../../data/models/loan_model.dart';

class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _purposeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _priority = 'media';
  String _selectedCategory = 'computer';
  bool _isSubmitting = false;
  bool _isRegisteredItem = true;
  String? _selectedItemId;
  String? _selectedWarehouseId; // Added warehouse selection
  
  List<dynamic> _availableItems = [];
  List<dynamic> _availableWarehouses = []; // Added warehouses list
  bool _isLoadingItems = false;
  bool _isLoadingWarehouses = false; // Added warehouse loading state
  late final ApiService _apiService;

  final Map<String, String> _categoryTranslations = {
    'computer': 'Equipos de Cómputo',
    'projector': 'Audiovisuales',
    'keyboard': 'Periféricos',
    'mouse': 'Periféricos',
    'tv': 'Audiovisuales',
    'camera': 'Audiovisuales',
    'microphone': 'Audiovisuales',
    'tablet': 'Equipos de Cómputo',
    'other': 'Otros',
  };

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _loadAvailableWarehouses(); // Load warehouses instead of items initially
  }

  Future<void> _loadAvailableWarehouses() async {
    setState(() {
      _isLoadingWarehouses = true;
    });

    try {
      final warehouses = await _apiService.get(loansWarehousesEndpoint);
      setState(() {
        _availableWarehouses = warehouses;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar almacenes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingWarehouses = false;
      });
    }
  }

  Future<void> _loadAvailableItems() async {
    if (_selectedWarehouseId == null) return;
    
    setState(() {
      _isLoadingItems = true;
    });

    try {
      final items = await _apiService.get(
        inventoryEndpoint,
        queryParams: {
          'environment_id': _selectedWarehouseId!,
          'status': 'available',
        },
      );
      setState(() {
        _availableItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar items: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingItems = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: const SenaAppBar(title: 'Solicitar Préstamo'),
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
                        'Información del Solicitante',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  color: AppColors.grey600,
                                ),
                              ),
                              if (user?.program != null)
                                Text(
                                  'Programa: ${user!.program}',
                                  style: const TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar Almacén',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingWarehouses)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedWarehouseId,
                          decoration: const InputDecoration(
                            labelText: 'Almacén de Destino',
                            border: OutlineInputBorder(),
                            hintText: 'Selecciona el almacén donde solicitar',
                          ),
                          itemHeight: 60.0,
                          selectedItemBuilder: (context) => _availableWarehouses.map((warehouse) {
                            return Text(
                              warehouse['name'] ?? 'Sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList(),
                          items: _availableWarehouses.map<DropdownMenuItem<String>>((warehouse) {
                            return DropdownMenuItem<String>(
                              value: warehouse['id'].toString(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      warehouse['name'] ?? 'Sin nombre',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    if (warehouse['location'] != null)
                                      Text(
                                        warehouse['location'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedWarehouseId = value;
                              _selectedItemId = null;
                              _availableItems.clear();
                            });
                            if (value != null && _isRegisteredItem) {
                              _loadAvailableItems();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona un almacén';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Solicitud',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Item Registrado'),
                              subtitle: const Text('Seleccionar de inventario'),
                              value: true,
                              groupValue: _isRegisteredItem,
                              onChanged: (value) {
                                setState(() {
                                  _isRegisteredItem = value!;
                                  _selectedItemId = null;
                                  _itemController.clear();
                                });
                                if (value! && _selectedWarehouseId != null) {
                                  _loadAvailableItems();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Item Personalizado'),
                              subtitle: const Text('Describir item necesario'),
                              value: false,
                              groupValue: _isRegisteredItem,
                              onChanged: (value) {
                                setState(() {
                                  _isRegisteredItem = value!;
                                  _selectedItemId = null;
                                  _itemController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isRegisteredItem) ...[ 
                if (_selectedWarehouseId != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categoría de Equipo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items: _categoryTranslations.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                                _selectedItemId = null;
                                _itemController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccionar Equipo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isLoadingItems)
                            const Center(child: CircularProgressIndicator())
                          else ...[ 
                            ...(_availableItems
                                .where((item) => item['category'] == _selectedCategory)
                                .map((item) => _buildItemTile(item))),
                            
                            if (_availableItems
                                .where((item) => item['category'] == _selectedCategory)
                                .isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No hay equipos disponibles en esta categoría',
                                    style: TextStyle(color: AppColors.grey600),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warehouse_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Selecciona un almacén primero',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Para ver los equipos disponibles, primero debes seleccionar el almacén donde deseas solicitar el préstamo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Describir Item Necesario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _itemNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Item',
                            border: OutlineInputBorder(),
                            hintText: 'Ej: Cable HDMI, Adaptador USB-C',
                          ),
                          validator: (value) {
                            if (!_isRegisteredItem && (value == null || value.isEmpty)) {
                              return 'Por favor ingresa el nombre del item';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _itemDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (Opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'Especificaciones técnicas, marca, modelo, etc.',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Préstamo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa la cantidad';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity < 1) {
                            return 'La cantidad debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de Inicio',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                      : 'Seleccionar fecha',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de Devolución',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'Seleccionar fecha',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'alta', child: Text('Alta')),
                          DropdownMenuItem(value: 'media', child: Text('Media')),
                          DropdownMenuItem(value: 'baja', child: Text('Baja')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _priority = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Propósito del Préstamo',
                          border: OutlineInputBorder(),
                          hintText: 'Describe para qué necesitas el equipo',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor describe el propósito del préstamo';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
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

  Widget _buildItemTile(Map<String, dynamic> item) {
    final isSelected = _selectedItemId == item['id'];
    final availableQuantity = (item['quantity'] ?? 0) - 
                             (item['quantity_damaged'] ?? 0) - 
                             (item['quantity_missing'] ?? 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: availableQuantity > 0 ? AppColors.success : AppColors.error,
          child: Icon(
            availableQuantity > 0 ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item['name'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${item['internal_code'] ?? 'N/A'}'),
            Text('Disponibles: $availableQuantity'),
            if (item['brand'] != null) Text('Marca: ${item['brand']}'),
          ],
        ),
        trailing: availableQuantity > 0
            ? Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primary,
              )
            : const Text(
                'No Disponible',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
        onTap: availableQuantity > 0
            ? () {
                setState(() {
                  _selectedItemId = isSelected ? null : item['id'];
                });
              }
            : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de fin es anterior a la de inicio, resetearla
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWarehouseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un almacén'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      if (_isRegisteredItem && _selectedItemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un equipo'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona las fechas de préstamo'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final loanProvider = Provider.of<LoanProvider>(context, listen: false);
        final user = authProvider.currentUser;

        final request = CreateLoanRequest(
          program: user?.program ?? 'Sin programa',
          purpose: _purposeController.text,
          startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
          priority: _priority,
          quantityRequested: int.parse(_quantityController.text),
          environmentId: _selectedWarehouseId!, // Use selected warehouse
          itemId: _isRegisteredItem ? _selectedItemId : null,
          isRegisteredItem: _isRegisteredItem,
          itemName: !_isRegisteredItem ? _itemNameController.text : null,
          itemDescription: !_isRegisteredItem ? _itemDescriptionController.text : null,
        );

        final success = await loanProvider.createLoan(request);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solicitud enviada exitosamente'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loanProvider.errorMessage ?? 'Error al enviar solicitud'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
    _itemController.dispose();
    _purposeController.dispose();
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}