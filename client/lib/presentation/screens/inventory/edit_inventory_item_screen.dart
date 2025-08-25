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
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item actualizado')));
        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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