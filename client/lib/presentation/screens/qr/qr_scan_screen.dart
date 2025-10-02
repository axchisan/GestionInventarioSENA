// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../data/models/environment_model.dart';
import '../../widgets/common/sena_app_bar.dart';

enum ScanMode { identify, linkEnvironment }

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  String? _scannedData;
  Map<String, dynamic>? _scannedPayload;
  List<dynamic> _environments = [];
  String? _selectedEnvironmentId;
  late final ApiService _apiService;
  
  late TabController _tabController;
  ScanMode _scanMode = ScanMode.identify;
  
  InventoryItemModel? _identifiedItem;
  EnvironmentModel? _identifiedEnvironment;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _scanMode = _tabController.index == 0 
              ? ScanMode.identify 
              : ScanMode.linkEnvironment;
          _resetScan();
        });
      }
    });
    _fetchEnvironments();
  }

  Future<void> _fetchEnvironments() async {
    try {
      final environments = await _apiService.get(environmentsEndpoint);
      setState(() {
        _environments = environments;
      });
    } catch (e) {
      _showSnackBar('Error al cargar ambientes: $e');
    }
  }

  void _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isScanning || _scannedData != null) return;

    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isScanning = true;
      _scannedData = barcode.rawValue;
    });

    try {
      // Parse QR payload
      final qrPayload = json.decode(_scannedData!);
      final qrType = qrPayload['type'];
      final entityId = qrPayload['id'];

      if (_scanMode == ScanMode.identify) {
        if (qrType == 'item') {
          await _identifyItem(entityId);
        } else if (qrType == 'environment') {
          await _identifyEnvironment(entityId);
        } else {
          _showSnackBar('Tipo de QR no reconocido');
          _resetScan();
        }
      } else {
        if (qrType != 'environment') {
          _showSnackBar('Solo puedes vincular QR de ambientes');
          _resetScan();
          return;
        }
        await _linkEnvironmentByQR();
      }
    } catch (e) {
      setState(() {
        _scannedData = null;
        _scannedPayload = null;
      });
      _showSnackBar('Error al procesar QR: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _identifyItem(String itemId) async {
    try {
      final response = await _apiService.getSingle('$inventoryEndpoint/$itemId');
      setState(() {
        _identifiedItem = InventoryItemModel.fromJson(response);
        _identifiedEnvironment = null;
      });
      _showSnackBar('Ítem identificado: ${_identifiedItem!.name}');
    } catch (e) {
      _showSnackBar('Error al identificar ítem: $e');
      _resetScan();
    }
  }

  Future<void> _identifyEnvironment(String environmentId) async {
    try {
      final response = await _apiService.getSingle('$environmentsEndpoint/$environmentId');
      setState(() {
        _identifiedEnvironment = EnvironmentModel.fromJson(response);
        _identifiedItem = null;
      });
      _showSnackBar('Ambiente identificado: ${_identifiedEnvironment!.name}');
    } catch (e) {
      _showSnackBar('Error al identificar ambiente: $e');
      _resetScan();
    }
  }

  Future<void> _linkEnvironmentByQR() async {
    try {
      final response = await _apiService.post('/api/qr/scan', {
        'qr_data': _scannedData,
      });
      setState(() {
        _scannedPayload = response;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkSession();
      _showSnackBar('Ambiente vinculado: ${response['environment']['name']}');
    } catch (e) {
      setState(() {
        _scannedData = null;
        _scannedPayload = null;
      });
      _showSnackBar('Error al vincular ambiente: $e');
    }
  }

  Future<void> _linkManually() async {
    if (_selectedEnvironmentId == null) {
      _showSnackBar('Selecciona un ambiente.');
      return;
    }

    try {
      final response = await _apiService.post('/api/users/link-environment', {
        'environment_id': _selectedEnvironmentId,
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkSession();
      _showSnackBar(
        'Ambiente vinculado manualmente: ${response['environment']['name']}',
      );
      setState(() {
        _scannedPayload = response;
      });
    } catch (e) {
      _showSnackBar('Error al vincular ambiente: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetScan() {
    setState(() {
      _scannedData = null;
      _scannedPayload = null;
      _selectedEnvironmentId = null;
      _identifiedItem = null;
      _identifiedEnvironment = null;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentUser?.role ?? '';

    return Scaffold(
      appBar: const SenaAppBar(title: 'Escanear Código QR'),
      body: Column(
        children: [
          Container(
            color: AppColors.grey100,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey600,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.search),
                  text: 'Identificar',
                ),
                Tab(
                  icon: Icon(Icons.link),
                  text: 'Vincular Ambiente',
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: _onDetect,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContentArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_scanMode == ScanMode.identify) {
      return _buildIdentifyContent();
    } else {
      return _buildLinkContent();
    }
  }

  Widget _buildIdentifyContent() {
    if (_identifiedItem != null) {
      return _buildItemDetails(_identifiedItem!);
    } else if (_identifiedEnvironment != null) {
      return _buildEnvironmentDetails(_identifiedEnvironment!);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.qr_code_scanner, size: 64, color: AppColors.grey400),
          SizedBox(height: 16),
          Text(
            'Escanea un código QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Identifica items o ambientes escaneando su código QR',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
        ],
      );
    }
  }

  Widget _buildItemDetails(InventoryItemModel item) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Categoría', item.categoryDisplayName),
                  _buildInfoRow('Estado', item.statusDisplayName),
                  _buildInfoRow('Código Interno', item.internalCode),
                  if (item.serialNumber != null)
                    _buildInfoRow('Número de Serie', item.serialNumber!),
                  if (item.brand != null)
                    _buildInfoRow('Marca', item.brand!),
                  if (item.model != null)
                    _buildInfoRow('Modelo', item.model!),
                  const Divider(height: 24),
                  _buildInfoRow('Cantidad Total', item.quantity.toString()),
                  _buildInfoRow('Disponibles', item.totalAvailable.toString()),
                  if (item.quantityDamaged > 0)
                    _buildInfoRow(
                      'Dañados',
                      item.quantityDamaged.toString(),
                      valueColor: AppColors.warning,
                    ),
                  if (item.quantityMissing > 0)
                    _buildInfoRow(
                      'Faltantes',
                      item.quantityMissing.toString(),
                      valueColor: AppColors.error,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/inventory-detail',
                    extra: item.id,
                  ),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver Detalles'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Escanear Otro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentDetails(EnvironmentModel environment) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: AppColors.success.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    environment.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Ubicación', environment.location),
                  _buildInfoRow('Código QR', environment.qrCode),
                  _buildInfoRow('Capacidad', '${environment.capacity} personas'),
                  _buildInfoRow(
                    'Tipo',
                    environment.isWarehouse ? 'Almacén' : 'Ambiente Regular',
                  ),
                  _buildInfoRow(
                    'Estado',
                    environment.isActive ? 'Activo' : 'Inactivo',
                    valueColor: environment.isActive 
                        ? AppColors.success 
                        : AppColors.grey600,
                  ),
                  if (environment.description != null) ...[
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Descripción:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      environment.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/environment-overview',
                    extra: {
                      'environmentId': environment.id,
                      'environmentName': environment.name,
                    },
                  ),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver Ambiente'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Escanear Otro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.grey700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkContent() {
    if (_scannedPayload != null) {
      return Column(
        children: [
          Card(
            color: AppColors.success.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ambiente Vinculado: ${_scannedPayload!['environment']['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubicación: ${_scannedPayload!['environment']['location']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Código: ${_scannedPayload!['environment']['qr_code']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/environment-overview',
                    extra: {
                      'environmentId':
                          _scannedPayload!['environment']['id'],
                      'environmentName':
                          _scannedPayload!['environment']['name'],
                    },
                  ),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Ver Ambiente'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Escanear Otro'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Escanea el código QR de un ambiente para vincularte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.grey600),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'O selecciona manualmente:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleccionar Ambiente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
              ),
              value: _selectedEnvironmentId,
              items: _environments
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['id'],
                      child: Text('${e['name']} · ${e['location']}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEnvironmentId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedEnvironmentId != null
                    ? _linkManually
                    : null,
                icon: const Icon(Icons.link),
                label: const Text('Vincular Manualmente'),
              ),
            ),
          ],
        ),
      );
    }
  }
}
