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
import '../../widgets/common/sena_app_bar.dart';

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

  @override
  void initState() {
    super.initState();
    // Inicializar ApiService primero
    _apiService = ApiService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    // Luego llamar a _fetchEnvironments
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
      final response = await _apiService.post('/api/qr/scan', {
        'qr_data': _scannedData,
      });
      setState(() {
        _scannedPayload = response;
      });

      // Actualizar el usuario en AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkSession(); // Refrescar datos del usuario
      _showSnackBar('Ambiente vinculado: ${response['environment']['name']}');
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
      await authProvider.checkSession(); // Refrescar datos del usuario
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
    });
  }

  @override
  void dispose() {
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
                  // Opcional: Configura el área de escaneo para imitar QrScannerOverlayShape
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_scannedPayload != null) ...[
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
                  ] else ...[
                    const Text(
                      'Posiciona el código QR dentro del marco',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.grey600),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Seleccionar Ambiente Manualmente',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
