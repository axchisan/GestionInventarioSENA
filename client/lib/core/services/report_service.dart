import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../constants/api_constants.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_check_model.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/maintenance_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/environment_model.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService;

  ReportService(this._apiService);

  Future<String> generateReport({
    required String reportType,
    required String format,
    DateTimeRange? dateRange,
    String? environmentId,
    bool includeImages = false,
    bool includeStatistics = true,
  }) async {
    try {
      // Obtener datos según el tipo de reporte
      Map<String, dynamic> reportData = await _getReportData(
        reportType, 
        dateRange, 
        environmentId
      );

      // Generar archivo según el formato
      String filePath;
      if (format.toLowerCase() == 'pdf') {
        filePath = await _generatePDFReport(
          reportType, 
          reportData, 
          includeImages, 
          includeStatistics
        );
      } else if (format.toLowerCase() == 'excel') {
        filePath = await _generateExcelReport(reportType, reportData);
      } else {
        throw Exception('Formato no soportado: $format');
      }

      return filePath;
    } catch (e) {
      throw Exception('Error generando reporte: $e');
    }
  }

  Future<Map<String, dynamic>> _getReportData(
    String reportType, 
    DateTimeRange? dateRange, 
    String? environmentId
  ) async {
    Map<String, String>? queryParams = {};
    
    if (dateRange != null) {
      queryParams['start_date'] = dateRange.start.toIso8601String().split('T')[0];
      queryParams['end_date'] = dateRange.end.toIso8601String().split('T')[0];
    }
    
    if (environmentId != null && environmentId != 'all') {
      queryParams['environment_id'] = environmentId;
    }

    switch (reportType) {
      case 'inventory':
        return await _getInventoryReportData(queryParams);
      case 'loans':
        return await _getLoansReportData(queryParams);
      case 'maintenance':
        return await _getMaintenanceReportData(queryParams);
      case 'audit':
        return await _getAuditReportData(queryParams);
      case 'statistics':
        return await _getStatisticsReportData(queryParams);
      default:
        throw Exception('Tipo de reporte no válido: $reportType');
    }
  }

  Future<Map<String, dynamic>> _getInventoryReportData(Map<String, String> queryParams) async {
    try {
      final inventoryData = await _apiService.get(inventoryEndpoint, queryParams: queryParams);
      final environmentsData = await _apiService.get(environmentsEndpoint);
      
      List<InventoryItemModel> items = inventoryData
          .map((item) => InventoryItemModel.fromJson(item))
          .toList();
      
      List<EnvironmentModel> environments = environmentsData
          .map((env) => EnvironmentModel.fromJson(env))
          .toList();

      return {
        'items': items,
        'environments': environments,
        'summary': {
          'total_items': items.length,
          'available_items': items.where((i) => i.status == 'available').length,
          'damaged_items': items.where((i) => i.status == 'damaged').length,
          'missing_items': items.where((i) => i.status == 'missing').length,
          'in_maintenance': items.where((i) => i.status == 'maintenance').length,
        }
      };
    } catch (e) {
      throw Exception('Error obteniendo datos de inventario: $e');
    }
  }

  Future<Map<String, dynamic>> _getLoansReportData(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      
      List<LoanModel> loans = loansData
          .map((loan) => LoanModel.fromJson(loan))
          .toList();

      return {
        'loans': loans,
        'summary': {
          'total_loans': loans.length,
          'active_loans': loans.where((l) => l.status == 'active').length,
          'pending_loans': loans.where((l) => l.status == 'pending').length,
          'overdue_loans': loans.where((l) => l.status == 'overdue').length,
          'returned_loans': loans.where((l) => l.status == 'returned').length,
        }
      };
    } catch (e) {
      throw Exception('Error obteniendo datos de préstamos: $e');
    }
  }

  Future<Map<String, dynamic>> _getMaintenanceReportData(Map<String, String> queryParams) async {
    try {
      final maintenanceData = await _apiService.get(maintenanceRequestsEndpoint, queryParams: queryParams);
      
      List<MaintenanceRequestModel> requests = maintenanceData
          .map((req) => MaintenanceRequestModel.fromJson(req))
          .toList();

      return {
        'requests': requests,
        'summary': {
          'total_requests': requests.length,
          'pending_requests': requests.where((r) => r.status == 'pending').length,
          'in_progress_requests': requests.where((r) => r.status == 'in_progress').length,
          'completed_requests': requests.where((r) => r.status == 'completed').length,
          'total_cost': requests.where((r) => r.cost != null).fold(0.0, (sum, r) => sum + r.cost!),
        }
      };
    } catch (e) {
      throw Exception('Error obteniendo datos de mantenimiento: $e');
    }
  }

  Future<Map<String, dynamic>> _getAuditReportData(Map<String, String> queryParams) async {
    try {
      final checksData = await _apiService.get(inventoryChecksEndpoint, queryParams: queryParams);
      
      List<InventoryCheckModel> checks = checksData
          .map((check) => InventoryCheckModel.fromJson(check))
          .toList();

      return {
        'checks': checks,
        'summary': {
          'total_checks': checks.length,
          'completed_checks': checks.where((c) => c.isComplete).length,
          'checks_with_issues': checks.where((c) => c.hasIssues).length,
          'compliance_rate': checks.isNotEmpty 
              ? (checks.where((c) => c.isComplete).length / checks.length * 100).round()
              : 0,
        }
      };
    } catch (e) {
      throw Exception('Error obteniendo datos de auditoría: $e');
    }
  }

  Future<Map<String, dynamic>> _getStatisticsReportData(Map<String, String> queryParams) async {
    try {
      final inventoryData = await _getInventoryReportData(queryParams);
      final loansData = await _getLoansReportData(queryParams);
      final maintenanceData = await _getMaintenanceReportData(queryParams);
      final auditData = await _getAuditReportData(queryParams);

      return {
        'inventory': inventoryData,
        'loans': loansData,
        'maintenance': maintenanceData,
        'audit': auditData,
        'generated_at': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error obteniendo datos estadísticos: $e');
    }
  }

  Future<String> _generatePDFReport(
    String reportType, 
    Map<String, dynamic> data, 
    bool includeImages, 
    bool includeStatistics
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildPDFHeader(reportType),
            pw.SizedBox(height: 20),
            _buildPDFContent(reportType, data, includeStatistics),
          ];
        },
      ),
    );

    return await _savePDFFile(pdf, reportType);
  }

  pw.Widget _buildPDFHeader(String reportType) {
    String title = _getReportTitle(reportType);
    
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SENA - Sistema de Gestión de Inventario',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(title, style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Text(
            'Generado: ${DateTime.now().toString().split('.')[0]}',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFContent(String reportType, Map<String, dynamic> data, bool includeStatistics) {
    switch (reportType) {
      case 'inventory':
        return _buildInventoryPDFContent(data, includeStatistics);
      case 'loans':
        return _buildLoansPDFContent(data, includeStatistics);
      case 'maintenance':
        return _buildMaintenancePDFContent(data, includeStatistics);
      case 'audit':
        return _buildAuditPDFContent(data, includeStatistics);
      case 'statistics':
        return _buildStatisticsPDFContent(data);
      default:
        return pw.Text('Tipo de reporte no implementado');
    }
  }

  pw.Widget _buildInventoryPDFContent(Map<String, dynamic> data, bool includeStatistics) {
    List<InventoryItemModel> items = data['items'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text('Resumen del Inventario', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Items')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['total_items'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Items Disponibles')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['available_items'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Items Dañados')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['damaged_items'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Items Faltantes')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['missing_items'] ?? 0}')),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Detalle de Items', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Categoría', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...items.map((item) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.name)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.categoryDisplayName)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.statusDisplayName)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.quantity}')),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLoansPDFContent(Map<String, dynamic> data, bool includeStatistics) {
    List<LoanModel> loans = data['loans'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text('Resumen de Préstamos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Préstamos')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['total_loans'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Préstamos Activos')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['active_loans'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Préstamos Vencidos')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['overdue_loans'] ?? 0}')),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Detalle de Préstamos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Programa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha Inicio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha Fin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...loans.map((loan) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(loan.program)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(loan.startDate.toString().split(' ')[0])),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(loan.endDate.toString().split(' ')[0])),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(loan.statusDisplayName)),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMaintenancePDFContent(Map<String, dynamic> data, bool includeStatistics) {
    List<MaintenanceRequestModel> requests = data['requests'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text('Resumen de Mantenimiento', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Solicitudes')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['total_requests'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Solicitudes Pendientes')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['pending_requests'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Solicitudes Completadas')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['completed_requests'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Costo Total')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('\$${summary['total_cost']?.toStringAsFixed(2) ?? '0.00'}')),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Detalle de Solicitudes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Título', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Prioridad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Costo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...requests.map((request) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(request.title)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(request.priorityDisplayName)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(request.statusDisplayName)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(request.cost != null ? '\$${request.cost!.toStringAsFixed(2)}' : 'N/A')),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAuditPDFContent(Map<String, dynamic> data, bool includeStatistics) {
    List<InventoryCheckModel> checks = data['checks'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text('Resumen de Auditoría', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total de Verificaciones')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['total_checks'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Verificaciones Completadas')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['completed_checks'] ?? 0}')),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tasa de Cumplimiento')),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${summary['compliance_rate'] ?? 0}%')),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Detalle de Verificaciones', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Items Totales', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Items Buenos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...checks.map((check) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(check.checkDate.toString().split(' ')[0])),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(check.statusDisplayName)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${check.totalItems ?? 0}')),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${check.itemsGood ?? 0}')),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStatisticsPDFContent(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Reporte Estadístico Completo', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        
        // Resumen de inventario
        if (data['inventory'] != null) ...[
          pw.Text('Inventario', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildInventoryPDFContent(data['inventory'], true),
          pw.SizedBox(height: 20),
        ],
        
        // Resumen de préstamos
        if (data['loans'] != null) ...[
          pw.Text('Préstamos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildLoansPDFContent(data['loans'], true),
          pw.SizedBox(height: 20),
        ],
        
        // Resumen de mantenimiento
        if (data['maintenance'] != null) ...[
          pw.Text('Mantenimiento', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildMaintenancePDFContent(data['maintenance'], true),
        ],
        
        // Resumen de auditoría
        if (data['audit'] != null) ...[
          pw.Text('Auditoría', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildAuditPDFContent(data['audit'], true),
        ],
      ],
    );
  }

  Future<String> _generateExcelReport(String reportType, Map<String, dynamic> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Reporte'];

    // Agregar encabezado
    sheet.cell(CellIndex.indexByString("A1")).value = TextCellValue('SENA - Sistema de Gestión de Inventario');
    sheet.cell(CellIndex.indexByString("A2")).value = TextCellValue(_getReportTitle(reportType));
    sheet.cell(CellIndex.indexByString("A3")).value = TextCellValue('Generado: ${DateTime.now().toString().split('.')[0]}');

    int currentRow = 5;

    switch (reportType) {
      case 'inventory':
        currentRow = _addInventoryDataToExcel(sheet, data, currentRow);
        break;
      case 'loans':
        currentRow = _addLoansDataToExcel(sheet, data, currentRow);
        break;
      case 'maintenance':
        currentRow = _addMaintenanceDataToExcel(sheet, data, currentRow);
        break;
      case 'audit':
        currentRow = _addAuditDataToExcel(sheet, data, currentRow);
        break;
      case 'statistics':
        currentRow = _addStatisticsDataToExcel(sheet, data, currentRow);
        break;
    }

    return await _saveExcelFile(excel, reportType);
  }

  int _addInventoryDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    List<InventoryItemModel> items = data['items'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE INVENTARIO');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Items');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['total_items'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Items Disponibles');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['available_items'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Items Dañados');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['damaged_items'] ?? 0);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE ITEMS');
    currentRow += 2;

    List<String> headers = ['Nombre', 'Categoría', 'Estado', 'Cantidad', 'Código Interno', 'Marca', 'Modelo'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de items
    for (var item in items) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(item.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(item.categoryDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(item.statusDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = IntCellValue(item.quantity);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(item.internalCode);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(item.brand ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = TextCellValue(item.model ?? '');
      currentRow++;
    }

    return currentRow;
  }

  int _addLoansDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    List<LoanModel> loans = data['loans'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE PRÉSTAMOS');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Préstamos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['total_loans'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Préstamos Activos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['active_loans'] ?? 0);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE PRÉSTAMOS');
    currentRow += 2;

    List<String> headers = ['Programa', 'Propósito', 'Fecha Inicio', 'Fecha Fin', 'Estado', 'Prioridad'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de préstamos
    for (var loan in loans) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(loan.program);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(loan.purpose);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(loan.startDate.toString().split(' ')[0]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(loan.endDate.toString().split(' ')[0]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(loan.statusDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(loan.priorityDisplayName);
      currentRow++;
    }

    return currentRow;
  }

  int _addMaintenanceDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    List<MaintenanceRequestModel> requests = data['requests'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE MANTENIMIENTO');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Solicitudes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['total_requests'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Costo Total');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = DoubleCellValue(summary['total_cost'] ?? 0.0);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE SOLICITUDES');
    currentRow += 2;

    List<String> headers = ['Título', 'Descripción', 'Prioridad', 'Estado', 'Costo', 'Fecha Creación'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de solicitudes
    for (var request in requests) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(request.title);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(request.description);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(request.priorityDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(request.statusDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = DoubleCellValue(request.cost ?? 0.0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(request.createdAt.toString().split(' ')[0]);
      currentRow++;
    }

    return currentRow;
  }

  int _addAuditDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    List<InventoryCheckModel> checks = data['checks'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE AUDITORÍA');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Verificaciones');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['total_checks'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Tasa de Cumplimiento');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue('${summary['compliance_rate'] ?? 0}%');
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE VERIFICACIONES');
    currentRow += 2;

    List<String> headers = ['Fecha', 'Estado', 'Items Totales', 'Items Buenos', 'Items Dañados', 'Items Faltantes'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de verificaciones
    for (var check in checks) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(check.checkDate.toString().split(' ')[0]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(check.statusDisplayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = IntCellValue(check.totalItems ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = IntCellValue(check.itemsGood ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = IntCellValue(check.itemsDamaged ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = IntCellValue(check.itemsMissing ?? 0);
      currentRow++;
    }

    return currentRow;
  }

  int _addStatisticsDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    int currentRow = startRow;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('REPORTE ESTADÍSTICO COMPLETO');
    currentRow += 2;

    if (data['inventory'] != null) {
      currentRow = _addInventoryDataToExcel(sheet, data['inventory'], currentRow);
      currentRow += 2;
    }

    if (data['loans'] != null) {
      currentRow = _addLoansDataToExcel(sheet, data['loans'], currentRow);
      currentRow += 2;
    }

    if (data['maintenance'] != null) {
      currentRow = _addMaintenanceDataToExcel(sheet, data['maintenance'], currentRow);
      currentRow += 2;
    }

    if (data['audit'] != null) {
      currentRow = _addAuditDataToExcel(sheet, data['audit'], currentRow);
    }

    return currentRow;
  }

  Future<String> _savePDFFile(pw.Document pdf, String reportType) async {
    try {
      final bytes = await pdf.save();
      final fileName = '${_getReportTitle(reportType)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      if (kIsWeb) {
        // Para web, usar download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        return fileName;
      } else {
        // Para móvil/escritorio
        final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Compartir el archivo
        await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado: $fileName');
        
        return filePath;
      }
    } catch (e) {
      throw Exception('Error guardando archivo PDF: $e');
    }
  }

  Future<String> _saveExcelFile(Excel excel, String reportType) async {
    try {
      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Error generando bytes del archivo Excel');
      }
      final fileName = '${_getReportTitle(reportType)}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      if (kIsWeb) {
        // Para web, usar download
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        return fileName;
      } else {
        // Para móvil/escritorio
        final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Compartir el archivo
        await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado: $fileName');
        
        return filePath;
      }
    } catch (e) {
      throw Exception('Error guardando archivo Excel: $e');
    }
  }

  String _getReportTitle(String reportType) {
    switch (reportType) {
      case 'inventory':
        return 'Reporte_Inventario';
      case 'loans':
        return 'Reporte_Prestamos';
      case 'maintenance':
        return 'Reporte_Mantenimiento';
      case 'audit':
        return 'Reporte_Auditoria';
      case 'statistics':
        return 'Reporte_Estadistico';
      default:
        return 'Reporte';
    }
  }

  Future<List<Map<String, dynamic>>> getRecentReports() async {
    try {
      // En una implementación real, esto vendría de un endpoint específico
      // Por ahora, devolvemos datos simulados basados en archivos locales
      return [
        {
          'name': 'Inventario_${DateTime.now().toString().split(' ')[0]}.pdf',
          'type': 'Inventario',
          'date': DateTime.now().toString().split(' ')[0],
          'size': '2.3 MB',
          'status': 'Completado',
        },
        {
          'name': 'Prestamos_${DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0]}.xlsx',
          'type': 'Préstamos',
          'date': DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0],
          'size': '1.8 MB',
          'status': 'Completado',
        },
      ];
    } catch (e) {
      print('Error obteniendo reportes recientes: $e');
      return [];
    }
  }

  Future<List<EnvironmentModel>> getEnvironments() async {
    try {
      final environmentsData = await _apiService.get(environmentsEndpoint);
      return environmentsData
          .map((env) => EnvironmentModel.fromJson(env))
          .toList();
    } catch (e) {
      print('Error obteniendo ambientes: $e');
      return [];
    }
  }

  // Método para mostrar un diálogo con la ruta del archivo guardado
  void showFileSavedDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivo Guardado'),
        content: Text('El archivo se ha guardado en: $filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}