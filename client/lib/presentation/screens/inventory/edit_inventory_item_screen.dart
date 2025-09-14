import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class EditInventoryItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditInventoryItemScreen({super.key, required this.item});

  @override
  State<EditInventoryItemScreen> createState() => _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState extends State<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _internalCode;
  late String _category;
  late int _quantity;
  late int _quantityDamaged;
  late int _quantityMissing;
  late String _itemType;
  late String _status;
  late String _serialNumber;
  late String _brand;
  late String _model;
  late DateTime? _purchaseDate;
  late DateTime? _warrantyExpiry;
  late DateTime? _lastMaintenance;
  late DateTime? _nextMaintenance;
  late String _imageUrl;
  late String _notes;
  late ApiService _apiService;
  bool _isLoading = false;

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
    'missing': 'Faltante',
    'good': 'Bueno',
  };

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _initializeFields();
  }

  void _initializeFields() {
    _name = widget.item['name'] ?? '';
    _internalCode = widget.item['internal_code'] ?? '';
    _category = widget.item['category'] ?? 'other';
    _quantity = widget.item['quantity'] ?? 1;
    _quantityDamaged = widget.item['quantity_damaged'] ?? 0;
    _quantityMissing = widget.item['quantity_missing'] ?? 0;
    _itemType = widget.item['item_type'] ?? 'individual';
    _status = widget.item['status'] ?? 'available';
    _serialNumber = widget.item['serial_number'] ?? '';
    _brand = widget.item['brand'] ?? '';
    _model = widget.item['model'] ?? '';
    _purchaseDate = widget.item['purchase_date'] != null ? DateTime.parse(widget.item['purchase_date']) : null;
    _warrantyExpiry = widget.item['warranty_expiry'] != null ? DateTime.parse(widget.item['warranty_expiry']) : null;
    _lastMaintenance = widget.item['last_maintenance'] != null ? DateTime.parse(widget.item['last_maintenance']) : null;
    _nextMaintenance = widget.item['next_maintenance'] != null ? DateTime.parse(widget.item['next_maintenance']) : null;
    _imageUrl = widget.item['image_url'] ?? '';
    _notes = widget.item['notes'] ?? '';
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_quantityDamaged + _quantityMissing > _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La suma de items dañados y faltantes no puede exceder la cantidad total'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final endpoint = '${inventoryEndpoint.replaceAll('/api/inventory/', '/api/inventory/')}${widget.item['id']}';
      
      await _apiService.put(
        endpoint,
        {
          'name': _name,
          'internal_code': _internalCode,
          'category': _category,
          'quantity': _quantity,
          'quantity_damaged': _quantityDamaged,
          'quantity_missing': _quantityMissing,
          'item_type': _itemType,
          'status': _status,
          'serial_number': _serialNumber.isEmpty ? null : _serialNumber,
          'brand': _brand.isEmpty ? null : _brand,
          'model': _model.isEmpty ? null : _model,
          'purchase_date': _purchaseDate?.toIso8601String(),
          'warranty_expiry': _warrantyExpiry?.toIso8601String(),
          'last_maintenance': _lastMaintenance?.toIso8601String(),
          'next_maintenance': _nextMaintenance?.toIso8601String(),
          'image_url': _imageUrl.isEmpty ? null : _imageUrl,
          'notes': _notes.isEmpty ? null : _notes,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(DateTime? initialDate, Function(DateTime?) setter) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        setter(picked);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No seleccionada';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Editar Item'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Información Básica',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      onChanged: (value) => _name = value,
                      validator: (value) => value?.isEmpty == true ? 'El nombre es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _internalCode,
                      decoration: const InputDecoration(
                        labelText: 'Código Interno *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      onChanged: (value) => _internalCode = value,
                      validator: (value) => value?.isEmpty == true ? 'El código interno es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categoryTranslations.entries.map((entry) => 
                        DropdownMenuItem(
                          value: entry.key, 
                          child: Text(entry.value)
                        )
                      ).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                      validator: (value) => value == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _itemType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Item *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.type_specimen),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'individual', child: Text('Individual')),
                        DropdownMenuItem(value: 'group', child: Text('Grupo')),
                      ],
                      onChanged: (value) => setState(() => _itemType = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Estado *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _statusTranslations.entries.map((entry) => 
                        DropdownMenuItem(
                          value: entry.key, 
                          child: Text(entry.value)
                        )
                      ).toList(),
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Gestión de Cantidades',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _quantity.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad Total *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _quantity = int.tryParse(value) ?? 1,
                            validator: (value) {
                              final qty = int.tryParse(value ?? '');
                              if (qty == null || qty < 1) {
                                return 'Cantidad debe ser mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _quantityDamaged.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad Dañada',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.warning, color: AppColors.warning),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _quantityDamaged = int.tryParse(value) ?? 0,
                            validator: (value) {
                              final qty = int.tryParse(value ?? '0');
                              if (qty == null || qty < 0) {
                                return 'Debe ser 0 o mayor';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _quantityMissing.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Faltante',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.error, color: AppColors.error),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _quantityMissing = int.tryParse(value) ?? 0,
                      validator: (value) {
                        final qty = int.tryParse(value ?? '0');
                        if (qty == null || qty < 0) {
                          return 'Debe ser 0 o mayor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getQuantityValidationColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getQuantityValidationMessage(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Additional details section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.details, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(
                            'Detalles Adicionales',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _serialNumber,
                      decoration: const InputDecoration(
                        labelText: 'Número de Serie (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      onChanged: (value) => _serialNumber = value,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _brand,
                            decoration: const InputDecoration(
                              labelText: 'Marca (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            onChanged: (value) => _brand = value,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _model,
                            decoration: const InputDecoration(
                              labelText: 'Modelo (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.model_training),
                            ),
                            onChanged: (value) => _model = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Dates section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'Fechas Importantes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart),
                        title: const Text('Fecha de Compra'),
                        subtitle: Text(_formatDate(_purchaseDate)),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _selectDate(_purchaseDate, (date) => _purchaseDate = date),
                      ),
                    ),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Vencimiento Garantía'),
                        subtitle: Text(_formatDate(_warrantyExpiry)),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _selectDate(_warrantyExpiry, (date) => _warrantyExpiry = date),
                      ),
                    ),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.build),
                        title: const Text('Último Mantenimiento'),
                        subtitle: Text(_formatDate(_lastMaintenance)),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _selectDate(_lastMaintenance, (date) => _lastMaintenance = date),
                      ),
                    ),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Próximo Mantenimiento'),
                        subtitle: Text(_formatDate(_nextMaintenance)),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _selectDate(_nextMaintenance, (date) => _nextMaintenance = date),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Imagen (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                      onChanged: (value) => _imageUrl = value,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                      onChanged: (value) => _notes = value,
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Actualizar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getQuantityValidationColor() {
    final total = _quantityDamaged + _quantityMissing;
    if (total == 0) {
      return AppColors.success;
    } else if (total <= _quantity) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getQuantityValidationMessage() {
    final total = _quantityDamaged + _quantityMissing;
    final available = _quantity - total;
    
    if (total == 0) {
      return 'Todos los items están disponibles ✓';
    } else if (total <= _quantity) {
      return 'Items disponibles: $available de $_quantity';
    } else {
      return 'Error: Total de dañados/faltantes excede cantidad total';
    }
  }
}
