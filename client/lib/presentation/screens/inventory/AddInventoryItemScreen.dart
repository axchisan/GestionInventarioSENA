import 'package:client/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _internalCode = '';
  String _category = 'other';
  int _quantity = 1;
  int _quantityDamaged = 0;
  int _quantityMissing = 0;
  String _itemType = 'individual';
  String _status = 'available';
  String _serialNumber = '';
  String _brand = '';
  String _model = '';
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DateTime? _lastMaintenance;
  DateTime? _nextMaintenance;
  String _imageUrl = '';
  String _notes = '';

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await _apiService.post(
          inventoryEndpoint,
          {
            'environment_id': authProvider.currentUser!.environmentId,
            'name': _name,
            'serial_number': _serialNumber.isEmpty ? null : _serialNumber,
            'internal_code': _internalCode,
            'category': _category,
            'brand': _brand.isEmpty ? null : _brand,
            'model': _model.isEmpty ? null : _model,
            'status': _status,
            'purchase_date': _purchaseDate?.toIso8601String(),
            'warranty_expiry': _warrantyExpiry?.toIso8601String(),
            'last_maintenance': _lastMaintenance?.toIso8601String(),
            'next_maintenance': _nextMaintenance?.toIso8601String(),
            'image_url': _imageUrl.isEmpty ? null : _imageUrl,
            'notes': _notes.isEmpty ? null : _notes,
            'quantity': _quantity,
            'quantity_damaged': _quantityDamaged,
            'quantity_missing': _quantityMissing,
            'item_type': _itemType,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item agregado')));
        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Agregar Item al Inventario'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (value) => _name = value,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Código Interno'),
                onChanged: (value) => _internalCode = value,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => _category = value!,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cantidades',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Total',
                          helperText: 'Cantidad total del item',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _quantity.toString(),
                        onChanged: (value) => setState(() => _quantity = int.tryParse(value) ?? 1),
                        validator: (value) {
                          final qty = int.tryParse(value!);
                          if (qty == null || qty < 1) return 'Debe ser mayor a 0';
                          if (qty < _quantityDamaged + _quantityMissing) {
                            return 'No puede ser menor que dañados + faltantes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Dañada',
                          helperText: 'Items que están dañados',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _quantityDamaged.toString(),
                        onChanged: (value) => setState(() => _quantityDamaged = int.tryParse(value) ?? 0),
                        validator: (value) {
                          final qty = int.tryParse(value!) ?? 0;
                          if (qty < 0) return 'No puede ser negativo';
                          if (qty + _quantityMissing > _quantity) {
                            return 'Dañados + faltantes no puede exceder el total';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Faltante',
                          helperText: 'Items que están perdidos o extraviados',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _quantityMissing.toString(),
                        onChanged: (value) => setState(() => _quantityMissing = int.tryParse(value) ?? 0),
                        validator: (value) {
                          final qty = int.tryParse(value!) ?? 0;
                          if (qty < 0) return 'No puede ser negativo';
                          if (qty + _quantityDamaged > _quantity) {
                            return 'Dañados + faltantes no puede exceder el total';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Disponibles: ${_quantity - _quantityDamaged - _quantityMissing}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _itemType,
                items: ['individual', 'group'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => _itemType = value!,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['available', 'in_use', 'maintenance', 'damaged', 'lost']
                    .map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                onChanged: (value) => _status = value!,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Número de Serie (opcional)'),
                onChanged: (value) => _serialNumber = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Marca (opcional)'),
                onChanged: (value) => _brand = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Modelo (opcional)'),
                onChanged: (value) => _model = value,
              ),
              ListTile(
                title: Text('Fecha de Compra: ${_purchaseDate?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_purchaseDate, (date) => _purchaseDate = date),
              ),
              ListTile(
                title: Text('Vencimiento Garantía: ${_warrantyExpiry?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_warrantyExpiry, (date) => _warrantyExpiry = date),
              ),
              ListTile(
                title: Text('Último Mantenimiento: ${_lastMaintenance?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_lastMaintenance, (date) => _lastMaintenance = date),
              ),
              ListTile(
                title: Text('Próximo Mantenimiento: ${_nextMaintenance?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_nextMaintenance, (date) => _nextMaintenance = date),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'URL Imagen (opcional)'),
                onChanged: (value) => _imageUrl = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                onChanged: (value) => _notes = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addItem,
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
