import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class QrCodeGeneratorScreen extends StatefulWidget {
  const QrCodeGeneratorScreen({super.key});

  @override
  State<QrCodeGeneratorScreen> createState() => _QrCodeGeneratorScreenState();
}

class _QrCodeGeneratorScreenState extends State<QrCodeGeneratorScreen> {
  final ApiService _apiService = ApiService();
  String _selectedType = 'ambiente'; // 'ambiente' | 'item'
  String _searchQuery = '';
  String? _selectedEnvironmentId;
  String? _selectedItemId;
  String? _qrData;
  Map<String, dynamic>? _qrPayload;
  final GlobalKey _qrBoundaryKey = GlobalKey();
  List<dynamic> _environments = [];
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchEnvironments();
    _fetchItems();
  }

  Future<void> _fetchEnvironments() async {
    try {
      final environments = await _apiService.get(environmentsEndpoint, queryParams: {'search': _searchQuery});
      setState(() {
        _environments = environments;
      });
    } catch (e) {
      _notify('Error al cargar ambientes: $e');
    }
  }

  Future<void> _fetchItems() async {
    try {
      final items = await _apiService.get(inventoryEndpoint, queryParams: {'search': _searchQuery});
      setState(() {
        _items = items;
      });
    } catch (e) {
      _notify('Error al cargar ítems: $e');
    }
  }

  Future<void> _generateQr() async {
    if (_selectedType == 'ambiente' && _selectedEnvironmentId == null) {
      _notify('Selecciona un ambiente.');
      return;
    }
    if (_selectedType == 'item' && _selectedItemId == null) {
      _notify('Selecciona un ítem.');
      return;
    }

    try {
      final entityType = _selectedType == 'ambiente' ? 'environment' : 'item';
      final entityId = _selectedType == 'ambiente' ? _selectedEnvironmentId : _selectedItemId;
      final response = await _apiService.getSingle('$qrGenerateEndpoint/$entityType/$entityId');
      setState(() {
        _qrData = response['qr_data']; // JSON completo por ahora
        _qrPayload = json.decode(_qrData!);
        // Usamos el 'id' como dato para el QR para simplificar
        _qrData = _qrPayload!['id']?.toString() ?? 'Invalid QR Data';
      });
    } catch (e) {
      _notify('Error al generar QR: $e');
    }
  }

  Future<Uint8List?> _captureQrPngBytes() async {
    try {
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _notify('No se pudo capturar el widget QR.');
        return null;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _notify('Error al capturar la imagen del QR: $e');
      return null;
    }
  }

  Future<void> _savePng() async {
    final bytes = await _captureQrPngBytes();
    if (bytes == null) return;
    if (kIsWeb) {
      _notify('Guardar no está disponible en la web.');
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      _notify('QR guardado: ${file.path}');
    } catch (e) {
      _notify('Error guardando el archivo: $e');
    }
  }

  Future<void> _sharePng() async {
    final bytes = await _captureQrPngBytes();
    if (bytes == null) return;
    if (kIsWeb) {
      _notify('Compartir no está disponible en la web.');
      return;
    }
    try {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Código QR generado');
    } catch (e) {
      _notify('Error al compartir el archivo: $e');
    }
  }

  Future<void> _printPng() async {
    final bytes = await _captureQrPngBytes();
    if (bytes == null) return;
    try {
      final doc = pw.Document();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Código QR - SENA', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 16),
                pw.Image(image, width: 240, height: 240),
                pw.SizedBox(height: 16),
                if (_qrPayload != null)
                  pw.Text(_qrPayload!['id']?.toString() ?? '', style: const pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (e) {
      _notify('Error al enviar a imprimir: $e');
    }
  }

  void _notify(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<dynamic> get _filteredEnvironments {
    if (_searchQuery.trim().isEmpty) return _environments;
    final q = _searchQuery.toLowerCase();
    return _environments.where((e) {
      return (e['id']?.toString().toLowerCase().contains(q) ?? false) ||
          (e['name']?.toLowerCase().contains(q) ?? false) ||
          (e['location']?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<dynamic> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) {
      return (i['id']?.toString().toLowerCase().contains(q) ?? false) ||
          (i['name']?.toLowerCase().contains(q) ?? false) ||
          (i['category']?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbiente = _selectedType == 'ambiente';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/sena_logo.png',
              height: 28,
              errorBuilder: (ctx, err, st) => const Icon(Icons.business, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('Generador de Códigos QR'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 12),
            _buildSearchBox(),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildExistingSelector(isAmbiente),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _generateQr,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Previsualizar QR'),
              ),
            ),
            const SizedBox(height: 16),
            _buildQrPreview(),
            const SizedBox(height: 12),
            _buildActionsRow(),
            const SizedBox(height: 16),
            _buildPayloadDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        ChoiceChip(
          selectedColor: AppColors.primary.withOpacity(0.15),
          label: const Text('Ambiente'),
          selected: _selectedType == 'ambiente',
          onSelected: (_) {
            setState(() {
              _selectedType = 'ambiente';
              _selectedItemId = null;
              _qrData = null;
              _qrPayload = null;
            });
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          selectedColor: AppColors.primary.withOpacity(0.15),
          label: const Text('Ítem de Inventario'),
          selected: _selectedType == 'item',
          onSelected: (_) {
            setState(() {
              _selectedType = 'item';
              _selectedEnvironmentId = null;
              _qrData = null;
              _qrPayload = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: _selectedType == 'ambiente'
            ? 'Buscar ambiente por ID, nombre o ubicación'
            : 'Buscar ítem por ID, nombre o categoría',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (v) {
        setState(() {
          _searchQuery = v;
        });
        if (_selectedType == 'ambiente') {
          _fetchEnvironments();
        } else {
          _fetchItems();
        }
      },
    );
  }

  Widget _buildExistingSelector(bool isAmbiente) {
    final items = isAmbiente ? _filteredEnvironments : _filteredItems;
    final selectedId = isAmbiente ? _selectedEnvironmentId : _selectedItemId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAmbiente ? 'Selecciona un ambiente' : 'Selecciona un ítem',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedId,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['id']?.toString(),
                  child: Text(
                    isAmbiente
                        ? '${e['id']} · ${e['name']} · ${e['location']}'
                        : '${e['id']} · ${e['name']} · ${e['category']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (val) {
            setState(() {
              if (isAmbiente) {
                _selectedEnvironmentId = val;
              } else {
                _selectedItemId = val;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isAmbiente
                    ? 'Los QR para ambientes codifican: id, nombre, ubicación, timestamp y firma.'
                    : 'Los QR para ítems codifican: id, nombre, categoría, timestamp y firma.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrPreview() {
    if (_qrData == null || _qrData!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: const [
            Icon(Icons.qr_code_2, size: 40, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Genera una previsualización del código QR para mostrarlo aquí.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: RepaintBoundary(
            key: _qrBoundaryKey,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.grey300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _qrData!,
                size: 240,
                backgroundColor: Colors.white,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                ),
                errorStateBuilder: (cxt, err) {
                  return Container(
                    color: Colors.red.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        'Error al renderizar QR: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _qrPayload?['id']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    final enabled = _qrData != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled && !kIsWeb ? _savePng : null,
            icon: const Icon(Icons.download),
            label: const Text('Guardar PNG'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? _printPng : null,
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: enabled && !kIsWeb ? _sharePng : null,
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadDetails() {
    if (_qrPayload == null) return const SizedBox.shrink();
    return ExpansionTile(
      title: const Text('Detalles del payload QR'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _kv('Versión', _qrPayload!['v']?.toString()),
        _kv('Tipo', _qrPayload!['type']),
        _kv('ID', _qrPayload!['id']),
        _kv('Código', _qrPayload!['code']),
        if (_qrPayload!['location'] != null) _kv('Ubicación', _qrPayload!['location']),
        if (_qrPayload!['category'] != null) _kv('Categoría', _qrPayload!['category']),
        _kv('Timestamp (seg)', _qrPayload!['ts']?.toString()),
        _kv('Firma (sha256)', _qrPayload!['sig']),
        const SizedBox(height: 8),
        SelectableText(
          _qrData!,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(v ?? '-'),
          ),
        ],
      ),
    );
  }
}