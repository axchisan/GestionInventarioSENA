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

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _name = widget.item['name'];
    _internalCode = widget.item['internal_code'];
    _category = widget.item['category'];
    _quantity = widget.item['quantity'] ?? 1;
    _itemType = widget.item['item_type'];
    _status = widget.item['status'];
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
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.put(
          '$inventoryEndpoint${widget.item['id']}',
          {
            'name': _name,
            'internal_code': _internalCode,
            'category': _category,
            'quantity': _quantity,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item actualizado')));
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
      appBar: const SenaAppBar(title: 'Editar Item'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (value) => _name = value,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                initialValue: _internalCode,
                decoration: const InputDecoration(labelText: 'Código Interno'),
                onChanged: (value) => _internalCode = value,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _quantity = int.tryParse(value) ?? 1,
                validator: (value) => int.tryParse(value!) == null ? 'Número válido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _itemType,
                items: ['individual', 'group'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _itemType = value!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['available', 'in_use', 'maintenance', 'damaged', 'lost']
                    .map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                onChanged: (value) => setState(() => _status = value!),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              TextFormField(
                initialValue: _serialNumber,
                decoration: const InputDecoration(labelText: 'Número de Serie (opcional)'),
                onChanged: (value) => _serialNumber = value,
              ),
              TextFormField(
                initialValue: _brand,
                decoration: const InputDecoration(labelText: 'Marca (opcional)'),
                onChanged: (value) => _brand = value,
              ),
              TextFormField(
                initialValue: _model,
                decoration: const InputDecoration(labelText: 'Modelo (opcional)'),
                onChanged: (value) => _model = value,
              ),
              ListTile(
                title: Text('Fecha de Compra: ${_purchaseDate?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_purchaseDate, (date) => setState(() => _purchaseDate = date)),
              ),
              ListTile(
                title: Text('Vencimiento Garantía: ${_warrantyExpiry?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_warrantyExpiry, (date) => setState(() => _warrantyExpiry = date)),
              ),
              ListTile(
                title: Text('Último Mantenimiento: ${_lastMaintenance?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_lastMaintenance, (date) => setState(() => _lastMaintenance = date)),
              ),
              ListTile(
                title: Text('Próximo Mantenimiento: ${_nextMaintenance?.toString() ?? 'No seleccionada'}'),
                onTap: () => _selectDate(_nextMaintenance, (date) => setState(() => _nextMaintenance = date)),
              ),
              TextFormField(
                initialValue: _imageUrl,
                decoration: const InputDecoration(labelText: 'URL Imagen (opcional)'),
                onChanged: (value) => _imageUrl = value,
              ),
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                onChanged: (value) => _notes = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateItem,
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}