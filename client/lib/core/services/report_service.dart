import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:printing/printing.dart';
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
      case 'inventory_checks':
        return await _getInventoryChecksReportData(queryParams);
      case 'environment_status':
        return await _getEnvironmentStatusReportData(queryParams);
      case 'alerts':
        return await _getAlertsReportData(queryParams);
      case 'users':
        return await _getUsersReportData(queryParams);
      case 'environments':
        return await _getEnvironmentsReportData(queryParams);
      default:
        throw Exception('Tipo de reporte no válido: $reportType');
    }
  }

  Future<Map<String, dynamic>> _getInventoryReportData(Map<String, String> queryParams) async {
    try {
      final inventoryData = await _apiService.get(inventoryEndpoint, queryParams: queryParams);
      final environmentsData = await _apiService.get(environmentsEndpoint);
      
      if (inventoryData == null) {
        throw Exception('No se pudieron obtener los datos de inventario');
      }
      
      List<InventoryItemModel> items = [];
      if (inventoryData is List) {
        for (var item in inventoryData) {
          try {
            items.add(InventoryItemModel.fromJson(item));
          } catch (e) {
            print('Error parsing inventory item: $e');
            // Continue with other items instead of failing completely
          }
        }
      }
      
      List<EnvironmentModel> environments = [];
      if (environmentsData is List) {
        for (var env in environmentsData) {
          try {
            environments.add(EnvironmentModel.fromJson(env));
          } catch (e) {
            print('Error parsing environment: $e');
            // Continue with other environments
          }
        }
      }

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

  Future<Map<String, dynamic>> _getInventoryChecksReportData(Map<String, String> queryParams) async {
    try {
      final checksData = await _apiService.get(inventoryChecksEndpoint, queryParams: queryParams);
      
      if (checksData == null) {
        return {'checks': [], 'total': 0};
      }
      
      if (checksData is List) {
        return <String, dynamic>{
          'checks': checksData,
          'total': checksData.length,
          'completed': checksData.where((c) => c['is_complete'] == true).length,
          'pending': checksData.where((c) => c['status'] == 'student_pending').length,
        };
      } else if (checksData is Map) {
        return Map<String, dynamic>.from(checksData);
      }
      
      return <String, dynamic>{'checks': [], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de verificaciones: $e');
      throw Exception('Error obteniendo datos de verificaciones: $e');
    }
  }

  Future<Map<String, dynamic>> _getEnvironmentStatusReportData(Map<String, String> queryParams) async {
    try {
      final environmentsData = await _apiService.get(environmentsEndpoint, queryParams: queryParams);
      
      if (environmentsData == null) {
        return <String, dynamic>{'environments': [], 'total': 0};
      }
      
      if (environmentsData is List) {
        return <String, dynamic>{
          'environments': environmentsData,
          'total': environmentsData.length,
          'active': environmentsData.where((e) => e['is_active'] == true).length,
          'warehouses': environmentsData.where((e) => e['is_warehouse'] == true).length,
        };
      } else if (environmentsData is Map) {
        return Map<String, dynamic>.from(environmentsData);
      }
      
      return <String, dynamic>{'environments': [], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de ambientes: $e');
      throw Exception('Error obteniendo datos de ambientes: $e');
    }
  }

  Future<Map<String, dynamic>> _getAlertsReportData(Map<String, String> queryParams) async {
    try {
      final alertsData = await _apiService.get(systemAlertsEndpoint, queryParams: queryParams);
      
      if (alertsData == null) {
        return <String, dynamic>{'alerts': [], 'total': 0};
      }
      
      if (alertsData is List) {
        return <String, dynamic>{
          'alerts': alertsData,
          'total': alertsData.length,
          'active': alertsData.where((a) => a['is_active'] == true).length,
          'critical': alertsData.where((a) => a['priority'] == 'critical').length,
        };
      } else if (alertsData is Map) {
        return Map<String, dynamic>.from(alertsData);
      }
      
      return <String, dynamic>{'alerts': [], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de alertas: $e');
      throw Exception('Error obteniendo datos de alertas: $e');
    }
  }

  Future<Map<String, dynamic>> _getUsersReportData(Map<String, String> queryParams) async {
    try {
      final usersData = await _apiService.get(usersEndpoint, queryParams: queryParams);
      
      if (usersData == null) {
        return <String, dynamic>{'users': [], 'total': 0};
      }
      
      if (usersData is List) {
        final List<Map<String, dynamic>> users = usersData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
            
        return <String, dynamic>{
          'users': users,
          'total': users.length,
          'by_role': _groupUsersByRole(users),
        };
      } else if (usersData is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(usersData);
        
        if (dataMap.containsKey('users') && dataMap['users'] is List) {
          final List<Map<String, dynamic>> users = (dataMap['users'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          dataMap['users'] = users;
          dataMap['by_role'] = _groupUsersByRole(users);
        }
        
        return dataMap;
      }
      
      return <String, dynamic>{'users': [], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de usuarios: $e');
      return <String, dynamic>{'users': [], 'total': 0, 'error': e.toString()};
    }
  }

  Map<String, int> _groupUsersByRole(List<Map<String, dynamic>> users) {
    final Map<String, int> roleCount = {};
    for (final user in users) {
      final role = user['role'] as String? ?? 'unknown';
      roleCount[role] = (roleCount[role] ?? 0) + 1;
    }
    return roleCount;
  }

  Future<Map<String, dynamic>> _getEnvironmentsReportData(Map<String, String> queryParams) async {
    try {
      final environmentsData = await _apiService.get(environmentsEndpoint, queryParams: queryParams);
      
      if (environmentsData == null) {
        return <String, dynamic>{'environments': [], 'total': 0};
      }
      
      if (environmentsData is List) {
        return <String, dynamic>{
          'environments': environmentsData,
          'total': environmentsData.length,
          'active': environmentsData.where((e) => e['is_active'] == true).length,
          'warehouses': environmentsData.where((e) => e['is_warehouse'] == true).length,
          'classrooms': environmentsData.where((e) => e['is_warehouse'] != true).length,
        };
      } else if (environmentsData is Map) {
        return Map<String, dynamic>.from(environmentsData);
      }
      
      return <String, dynamic>{'environments': [], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de ambientes: $e');
      throw Exception('Error obteniendo datos de ambientes: $e');
    }
  }

  Future<Map<String, dynamic>> _getLoansReportData(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      
      if (loansData == null) {
        return <String, dynamic>{'loans': <LoanModel>[], 'total': 0};
      }
      
      if (loansData is List) {
        final List<LoanModel> loans = loansData
            .map((item) => LoanModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
            
        return <String, dynamic>{
          'loans': loans,
          'total': loans.length,
          'active': loans.where((l) => l.status == 'active').length,
          'pending': loans.where((l) => l.status == 'pending').length,
          'overdue': loans.where((l) => l.status == 'overdue').length,
        };
      } else if (loansData is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(loansData);
        
        if (dataMap.containsKey('loans') && dataMap['loans'] is List) {
          final List<LoanModel> loans = (dataMap['loans'] as List)
              .map((item) => LoanModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          dataMap['loans'] = loans;
        }
        
        return dataMap;
      }
      
      return <String, dynamic>{'loans': <LoanModel>[], 'total': 0};
    } catch (e) {
      print('Error obteniendo datos de préstamos: $e');
      return <String, dynamic>{'loans': <LoanModel>[], 'total': 0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getMaintenanceReportData(Map<String, String> queryParams) async {
    try {
      final maintenanceData = await _apiService.get(maintenanceRequestsEndpoint, queryParams: queryParams);
      
      if (maintenanceData == null) {
        throw Exception('No se pudieron obtener los datos de mantenimiento');
      }
      
      List<MaintenanceRequestModel> requests = [];
      if (maintenanceData is List) {
        for (var req in maintenanceData) {
          try {
            requests.add(MaintenanceRequestModel.fromJson(req));
          } catch (e) {
            print('Error parsing maintenance request: $e');
            // Continue with other requests
          }
        }
      }

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
      final auditData = await _apiService.get('/audit-logs', queryParams: queryParams);
      
      if (auditData == null) {
        throw Exception('No se pudieron obtener los datos de auditoría');
      }
      
      List<Map<String, dynamic>> auditLogs = [];
      if (auditData is List) {
        auditLogs = List<Map<String, dynamic>>.from(auditData);
      }

      Map<String, int> actionCounts = {};
      Map<String, int> userCounts = {};
      Map<String, int> entityCounts = {};
      int successfulActions = 0;
      int failedActions = 0;

      for (var log in auditLogs) {
        // Count actions
        String action = log['action'] ?? 'unknown';
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;

        // Count users
        String userEmail = log['user_email'] ?? 'unknown';
        userCounts[userEmail] = (userCounts[userEmail] ?? 0) + 1;

        // Count entities
        String entityType = log['entity_type'] ?? 'unknown';
        entityCounts[entityType] = (entityCounts[entityType] ?? 0) + 1;

        // Count success/failure based on status code
        Map<String, dynamic>? newValues = log['new_values'];
        if (newValues != null) {
          Map<String, dynamic>? response = newValues['response'];
          if (response != null) {
            int statusCode = response['status_code'] ?? 0;
            if (statusCode >= 200 && statusCode < 400) {
              successfulActions++;
            } else {
              failedActions++;
            }
          }
        }
      }

      return {
        'audit_logs': auditLogs,
        'summary': {
          'total_actions': auditLogs.length,
          'successful_actions': successfulActions,
          'failed_actions': failedActions,
          'success_rate': auditLogs.isNotEmpty 
              ? (successfulActions / auditLogs.length * 100).round()
              : 0,
          'unique_users': userCounts.length,
          'most_active_user': userCounts.isNotEmpty 
              ? userCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
              : 'N/A',
          'action_breakdown': actionCounts,
          'entity_breakdown': entityCounts,
        }
      };
    } catch (e) {
      throw Exception('Error obteniendo datos de auditoría: $e');
    }
  }

  Future<Map<String, dynamic>> _getStatisticsReportData(Map<String, String> queryParams) async {
    try {
      Map<String, dynamic> result = {
        'generated_at': DateTime.now(),
      };
      
      try {
        result['inventory'] = await _getInventoryReportData(queryParams);
      } catch (e) {
        print('Error getting inventory data for statistics: $e');
        result['inventory'] = {'items': [], 'environments': [], 'summary': {}};
      }
      
      try {
        result['loans'] = await _getLoansReportData(queryParams);
      } catch (e) {
        print('Error getting loans data for statistics: $e');
        result['loans'] = {'loans': [], 'summary': {}};
      }
      
      try {
        result['maintenance'] = await _getMaintenanceReportData(queryParams);
      } catch (e) {
        print('Error getting maintenance data for statistics: $e');
        result['maintenance'] = {'requests': [], 'summary': {}};
      }
      
      try {
        result['audit'] = await _getAuditReportData(queryParams);
      } catch (e) {
        print('Error getting audit data for statistics: $e');
        result['audit'] = {'audit_logs': [], 'summary': {}};
      }

      return result;
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
    
    pw.Font? regularFont;
    pw.Font? boldFont;
    
    try {
      // Try to load system fonts that support Unicode
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, use built-in fonts
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      } else {
        // For desktop platforms, try to load system fonts
        try {
          regularFont = await PdfGoogleFonts.notoSansRegular();
          boldFont = await PdfGoogleFonts.notoSansBold();
        } catch (e) {
          print('Could not load Google Fonts, using fallback fonts: $e');
          // Fallback to basic fonts if Google Fonts are not available
          regularFont = pw.Font.helvetica();
          boldFont = pw.Font.helveticaBold();
        }
      }
    } catch (e) {
      print('Error loading fonts: $e');
      // Ultimate fallback to basic fonts
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            _buildPDFHeader(reportType, boldFont, regularFont),
            pw.SizedBox(height: 20),
            _buildPDFContent(reportType, data, includeStatistics, boldFont, regularFont),
          ];
        },
      ),
    );

    return await _savePDFFile(pdf, reportType);
  }

  pw.Widget _buildPDFHeader(String reportType, pw.Font? boldFont, pw.Font? regularFont) {
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
                style: pw.TextStyle(
                  fontSize: 16, 
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.Text(
                title, 
                style: pw.TextStyle(
                  fontSize: 14,
                  font: regularFont,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generado: ${DateTime.now().toString().split('.')[0]}',
            style: pw.TextStyle(
              fontSize: 10,
              font: regularFont,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFContent(String reportType, Map<String, dynamic> data, bool includeStatistics, pw.Font? boldFont, pw.Font? regularFont) {
    switch (reportType) {
      case 'inventory':
        return _buildInventoryPDFContent(data, includeStatistics, boldFont, regularFont);
      case 'loans':
        return _buildLoansPDFContent(data, includeStatistics, boldFont, regularFont);
      case 'maintenance':
        return _buildMaintenancePDFContent(data, includeStatistics, boldFont, regularFont);
      case 'audit':
        return _buildAuditPDFContent(data, includeStatistics, boldFont, regularFont);
      case 'statistics':
        return _buildStatisticsPDFContent(data, boldFont, regularFont);
      // Added PDF content builders for new report types
      case 'inventory_checks':
        return _buildInventoryChecksPDFContent(data, boldFont, regularFont);
      case 'environment_status':
        return _buildEnvironmentStatusPDFContent(data, boldFont, regularFont);
      case 'alerts':
        return _buildAlertsPDFContent(data, boldFont, regularFont);
      case 'users':
        return _buildUsersPDFContent(data, boldFont, regularFont);
      case 'environments':
        return _buildEnvironmentsPDFContent(data, boldFont, regularFont);
      default:
        return pw.Text(
          'Tipo de reporte no implementado',
          style: pw.TextStyle(font: regularFont),
        );
    }
  }

  pw.Widget _buildInventoryPDFContent(Map<String, dynamic> data, bool includeStatistics, pw.Font? boldFont, pw.Font? regularFont) {
    List<InventoryItemModel> items = data['items'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text(
            'Resumen del Inventario', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Total de Items',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['total_items'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Disponibles',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['available_items'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Dañados',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['damaged_items'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Faltantes',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['missing_items'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'Detalle de Items', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
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
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Nombre', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Categoría', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Cantidad', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...items.map((item) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  item.name,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  item.categoryDisplayName,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  item.statusDisplayName,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${item.quantity}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLoansPDFContent(Map<String, dynamic> data, bool includeStatistics, pw.Font? boldFont, pw.Font? regularFont) {
    List<LoanModel> loans = data['loans'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text(
            'Resumen de Préstamos', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Total de Préstamos',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['total_loans'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Préstamos Activos',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['active_loans'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Préstamos Vencidos',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['overdue_loans'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'Detalle de Préstamos', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
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
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Programa', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha Inicio', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha Fin', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...loans.map((loan) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  loan.program,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  loan.startDate.toString().split(' ')[0],
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  loan.endDate.toString().split(' ')[0],
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  loan.statusDisplayName,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMaintenancePDFContent(Map<String, dynamic> data, bool includeStatistics, pw.Font? boldFont, pw.Font? regularFont) {
    List<MaintenanceRequestModel> requests = data['requests'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text(
            'Resumen de Mantenimiento', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Total de Solicitudes',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['total_requests'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Solicitudes Pendientes',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['pending_requests'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Solicitudes Completadas',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['completed_requests'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Costo Total',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '\$${summary['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'Detalle de Solicitudes', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
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
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Título', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Prioridad', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Costo', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...requests.map((request) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  request.title,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  request.priorityDisplayName,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  request.statusDisplayName,
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  request.cost != null ? '\$${request.cost!.toStringAsFixed(2)}' : 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAuditPDFContent(Map<String, dynamic> data, bool includeStatistics, pw.Font? boldFont, pw.Font? regularFont) {
    List<Map<String, dynamic>> auditLogs = data['audit_logs'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (includeStatistics) ...[
          pw.Text(
            'Resumen de Auditoría', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Total de Acciones',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['total_actions'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Acciones Exitosas',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['successful_actions'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Tasa de Éxito',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['success_rate'] ?? 0}%',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Usuarios Únicos',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['unique_users'] ?? 0}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Usuario Más Activo',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    '${summary['most_active_user'] ?? 'N/A'}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'Detalle de Registros de Auditoría', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Usuario', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Acción', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Entidad', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Código Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...auditLogs.map((log) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  log['timestamp']?.toString().split(' ')[0] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  log['user_email'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  log['action'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  log['entity_type'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  log['new_values']?['response']?['status_code'] != null 
                      ? (log['new_values']['response']['status_code'] >= 200 && log['new_values']['response']['status_code'] < 400 ? 'Éxito' : 'Fallo')
                      : 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${log['new_values']?['response']?['status_code'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInventoryChecksPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    final checks = data['checks'] ?? [];
    final total = data['total'] ?? 0;
    final completed = data['completed'] ?? 0;
    final pending = data['pending'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Verificaciones', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Total de Verificaciones',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Verificaciones Completadas',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$completed',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Verificaciones Pendientes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$pending',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Detalle de Verificaciones', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'ID', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Totales', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Buenos', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Dañados', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Items Faltantes', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...checks.map((check) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${check['id'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  check['check_date']?.toString().split(' ')[0] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  check['status'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${check['total_items'] ?? 0}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${check['items_good'] ?? 0}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${check['items_damaged'] ?? 0}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${check['items_missing'] ?? 0}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEnvironmentStatusPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    final environments = data['environments'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final warehouses = data['warehouses'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Estado de Ambientes', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Total de Ambientes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Ambientes Activos',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$active',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Almacenes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$warehouses',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Detalle de Ambientes', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'ID', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Nombre', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Activo', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Almacén', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...environments.map((env) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${env['id'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['name'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['is_active'] == true ? 'Sí' : 'No',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['is_warehouse'] == true ? 'Sí' : 'No',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAlertsPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    final alerts = data['alerts'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final critical = data['critical'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Alertas', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Total de Alertas',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Alertas Activas',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$active',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Alertas Críticas',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$critical',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Detalle de Alertas', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'ID', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Mensaje', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Prioridad', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...alerts.map((alert) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${alert['id'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  alert['message'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  alert['priority'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  alert['is_active'] == true ? 'Activa' : 'Inactiva',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  alert['created_at']?.toString().split(' ')[0] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildUsersPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    final users = data['users'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final students = data['students'] ?? 0;
    final instructors = data['instructors'] ?? 0;
    final admins = data['admins'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Usuarios', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Total de Usuarios',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Usuarios Activos',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$active',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Estudiantes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$students',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Instructores',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$instructors',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Administradores',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$admins',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Detalle de Usuarios', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'ID', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Nombre', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Rol', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Estado', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Fecha Registro', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...users.map((user) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${user['id'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  user['name'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  user['role'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  user['is_active'] == true ? 'Activo' : 'Inactivo',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  user['created_at']?.toString().split(' ')[0] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEnvironmentsPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    final environments = data['environments'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final warehouses = data['warehouses'] ?? 0;
    final classrooms = data['classrooms'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Ambientes', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Total de Ambientes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Ambientes Activos',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$active',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Almacenes',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$warehouses',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  'Salones',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '$classrooms',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Detalle de Ambientes', 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'ID', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Nombre', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Tipo', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Activo', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5), 
                  child: pw.Text(
                    'Almacén', 
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ),
              ],
            ),
            ...environments.map((env) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  '${env['id'] ?? 'N/A'}',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['name'] ?? 'N/A',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['is_warehouse'] == true ? 'Almacén' : 'Salón',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['is_active'] == true ? 'Sí' : 'No',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5), 
                child: pw.Text(
                  env['is_warehouse'] == true ? 'Sí' : 'No',
                  style: pw.TextStyle(font: regularFont),
                ),
              ),
            ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStatisticsPDFContent(Map<String, dynamic> data, pw.Font? boldFont, pw.Font? regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Reporte Estadístico Completo', 
          style: pw.TextStyle(
            fontSize: 16, 
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 20),
        
        // Resumen de inventario
        if (data['inventory'] != null) ...[
          pw.Text(
            'Inventario', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInventoryPDFContent(data['inventory'], true, boldFont, regularFont),
          pw.SizedBox(height: 20),
        ],
        
        // Resumen de préstamos
        if (data['loans'] != null) ...[
          pw.Text(
            'Préstamos', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildLoansPDFContent(data['loans'], true, boldFont, regularFont),
          pw.SizedBox(height: 20),
        ],
        
        // Resumen de mantenimiento
        if (data['maintenance'] != null) ...[
          pw.Text(
            'Mantenimiento', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildMaintenancePDFContent(data['maintenance'], true, boldFont, regularFont),
        ],
        
        // Resumen de auditoría
        if (data['audit'] != null) ...[
          pw.Text(
            'Auditoría', 
            style: pw.TextStyle(
              fontSize: 14, 
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildAuditPDFContent(data['audit'], true, boldFont, regularFont),
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
      // Added Excel data methods for new report types
      case 'inventory_checks':
        currentRow = _addInventoryChecksDataToExcel(sheet, data, currentRow);
        break;
      case 'environment_status':
        currentRow = _addEnvironmentStatusDataToExcel(sheet, data, currentRow);
        break;
      case 'alerts':
        currentRow = _addAlertsDataToExcel(sheet, data, currentRow);
        break;
      case 'users':
        currentRow = _addUsersDataToExcel(sheet, data, currentRow);
        break;
      case 'environments':
        currentRow = _addEnvironmentsDataToExcel(sheet, data, currentRow);
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
    List<Map<String, dynamic>> auditLogs = data['audit_logs'] ?? [];
    Map<String, dynamic> summary = data['summary'] ?? {};
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE AUDITORÍA');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Acciones');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['total_actions'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Acciones Exitosas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(summary['successful_actions'] ?? 0);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Tasa de Éxito');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue('${summary['success_rate'] ?? 0}%');
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE REGISTROS DE AUDITORÍA');
    currentRow += 2;

    List<String> headers = ['Fecha', 'Usuario', 'Acción', 'Entidad', 'Estado', 'Código Estado'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de auditoría
    for (var log in auditLogs) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(log['timestamp']?.toString().split(' ')[0] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(log['user_email'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(log['action'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(log['entity_type'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(log['new_values']?['response']?['status_code'] != null 
          ? (log['new_values']['response']['status_code'] >= 200 && log['new_values']['response']['status_code'] < 400 ? 'Éxito' : 'Fallo')
          : 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue('${log['new_values']?['response']?['status_code'] ?? 'N/A'}');
      currentRow++;
    }

    return currentRow;
  }

  // Added Excel data methods for new report types
  int _addInventoryChecksDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final checks = data['checks'] ?? [];
    final total = data['total'] ?? 0;
    final completed = data['completed'] ?? 0;
    final pending = data['pending'] ?? 0;
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE VERIFICACIONES');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Verificaciones');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(total);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Verificaciones Completadas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(completed);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Verificaciones Pendientes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(pending);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE VERIFICACIONES');
    currentRow += 2;

    List<String> headers = ['ID', 'Fecha', 'Estado', 'Items Totales', 'Items Buenos', 'Items Dañados', 'Items Faltantes'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de verificaciones
    for (var check in checks) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('${check['id'] ?? 'N/A'}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(check['check_date']?.toString().split(' ')[0] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(check['status'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = IntCellValue(check['total_items'] ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = IntCellValue(check['items_good'] ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = IntCellValue(check['items_damaged'] ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = IntCellValue(check['items_missing'] ?? 0);
      currentRow++;
    }

    return currentRow;
  }

  int _addEnvironmentStatusDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final environments = data['environments'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final warehouses = data['warehouses'] ?? 0;
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE ESTADO DE AMBIENTES');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Ambientes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(total);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Ambientes Activos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(active);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Almacenes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(warehouses);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE AMBIENTES');
    currentRow += 2;

    List<String> headers = ['ID', 'Nombre', 'Activo', 'Almacén'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de ambientes
    for (var env in environments) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('${env['id'] ?? 'N/A'}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(env['name'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(env['is_active'] == true ? 'Sí' : 'No');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(env['is_warehouse'] == true ? 'Sí' : 'No');
      currentRow++;
    }

    return currentRow;
  }

  int _addAlertsDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final alerts = data['alerts'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final critical = data['critical'] ?? 0;
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE ALERTAS');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Alertas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(total);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Alertas Activas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(active);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Alertas Críticas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(critical);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE ALERTAS');
    currentRow += 2;

    List<String> headers = ['ID', 'Mensaje', 'Prioridad', 'Estado', 'Fecha'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de alertas
    for (var alert in alerts) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('${alert['id'] ?? 'N/A'}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(alert['message'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(alert['priority'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(alert['is_active'] == true ? 'Activa' : 'Inactiva');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(alert['created_at']?.toString().split(' ')[0] ?? 'N/A');
      currentRow++;
    }

    return currentRow;
  }

  int _addUsersDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final users = data['users'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final students = data['students'] ?? 0;
    final instructors = data['instructors'] ?? 0;
    final admins = data['admins'] ?? 0;
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE USUARIOS');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Usuarios');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(total);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Usuarios Activos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(active);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Estudiantes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(students);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Instructores');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(instructors);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Administradores');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(admins);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE USUARIOS');
    currentRow += 2;

    List<String> headers = ['ID', 'Nombre', 'Rol', 'Estado', 'Fecha Registro'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de usuarios
    for (var user in users) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('${user['id'] ?? 'N/A'}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(user['name'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(user['role'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(user['is_active'] == true ? 'Activo' : 'Inactivo');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(user['created_at']?.toString().split(' ')[0] ?? 'N/A');
      currentRow++;
    }

    return currentRow;
  }

  int _addEnvironmentsDataToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final environments = data['environments'] ?? [];
    final total = data['total'] ?? 0;
    final active = data['active'] ?? 0;
    final warehouses = data['warehouses'] ?? 0;
    final classrooms = data['classrooms'] ?? 0;
    
    int currentRow = startRow;

    // Agregar resumen
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('RESUMEN DE AMBIENTES');
    currentRow += 2;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Total de Ambientes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(total);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Ambientes Activos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(active);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Almacenes');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(warehouses);
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Salones');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(classrooms);
    currentRow += 3;

    // Agregar encabezados de detalle
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('DETALLE DE AMBIENTES');
    currentRow += 2;

    List<String> headers = ['ID', 'Nombre', 'Tipo', 'Activo', 'Almacén'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).value = TextCellValue(headers[i]);
    }
    currentRow++;

    // Agregar datos de ambientes
    for (var env in environments) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('${env['id'] ?? 'N/A'}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(env['name'] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(env['is_warehouse'] == true ? 'Almacén' : 'Salón');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(env['is_active'] == true ? 'Sí' : 'No');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(env['is_warehouse'] == true ? 'Sí' : 'No');
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
        Directory? directory;
        try {
          if (Platform.isAndroid || Platform.isIOS) {
            // Para móviles, usar directorio de documentos
            directory = await getApplicationDocumentsDirectory();
          } else {
            // Para escritorio, intentar descargas primero
            directory = await getDownloadsDirectory();
          }
        } catch (e) {
          print('Error getting preferred directory: $e');
        }
        
        // Fallback al directorio temporal si no se puede acceder al preferido
        directory ??= await getTemporaryDirectory();
        
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        try {
          if (Platform.isLinux) {
            // En Linux, solo mostrar la ruta del archivo sin intentar compartir
            print('Archivo guardado en: $filePath');
            return filePath;
          } else {
            // Compartir el archivo en otras plataformas
            await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado: $fileName');
          }
        } catch (shareError) {
          print('Error compartiendo archivo: $shareError');
          // El archivo se guardó correctamente, solo falló el compartir
        }
        
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
        Directory? directory;
        try {
          if (Platform.isAndroid || Platform.isIOS) {
            directory = await getApplicationDocumentsDirectory();
          } else {
            directory = await getDownloadsDirectory();
          }
        } catch (e) {
          print('Error getting preferred directory: $e');
        }
        
        directory ??= await getTemporaryDirectory();
        
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        try {
          if (Platform.isLinux) {
            print('Archivo guardado en: $filePath');
            return filePath;
          } else {
            await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado: $fileName');
          }
        } catch (shareError) {
          print('Error compartiendo archivo: $shareError');
        }
        
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
      case 'inventory_checks':
        return 'Reporte_Verificaciones';
      case 'environment_status':
        return 'Reporte_Estado_Ambientes';
      case 'alerts':
        return 'Reporte_Alertas';
      case 'users':
        return 'Reporte_Usuarios';
      case 'environments':
        return 'Reporte_Ambientes';
      default:
        return 'Reporte';
    }
  }

  Future<List<Map<String, dynamic>>> getRecentReports() async {
    try {
      final reportsData = await _apiService.get(reportsEndpoint);
      
      if (reportsData is List) {
        return reportsData.map((report) => {
          'name': report['title'] ?? 'Reporte sin nombre',
          'type': report['report_type'] ?? 'Desconocido',
          'date': report['created_at']?.toString().split('T')[0] ?? DateTime.now().toString().split(' ')[0],
          'size': _formatFileSize(report['file_size']),
          'status': _getStatusDisplayName(report['status'] ?? 'completed'),
          'id': report['id'],
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('Error obteniendo reportes recientes: $e');
      return [
        {
          'name': 'Inventario_${DateTime.now().toString().split(' ')[0]}.pdf',
          'type': 'Inventario',
          'date': DateTime.now().toString().split(' ')[0],
          'size': '2.3 MB',
          'status': 'Completado',
          'id': 'mock_1',
        },
        {
          'name': 'Prestamos_${DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0]}.xlsx',
          'type': 'Préstamos',
          'date': DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0],
          'size': '1.8 MB',
          'status': 'Completado',
          'id': 'mock_2',
        },
      ];
    }
  }

  String _formatFileSize(dynamic fileSize) {
    if (fileSize == null) return 'N/A';
    
    int bytes = fileSize is int ? fileSize : 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'generating':
        return 'Generando';
      case 'completed':
        return 'Completado';
      case 'failed':
        return 'Fallido';
      default:
        return 'Desconocido';
    }
  }

  Future<String> generateReportViaAPI({
    required String reportType,
    required String format,
    required String title,
    DateTimeRange? dateRange,
    String? environmentId,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        'report_type': reportType,
        'file_format': format,
        'title': title,
        'parameters': <String, dynamic>{},
      };

      // Add date range parameters if provided
      if (dateRange != null) {
        requestBody['parameters']['start_date'] = dateRange.start.toIso8601String().split('T')[0];
        requestBody['parameters']['end_date'] = dateRange.end.toIso8601String().split('T')[0];
      }

      // Add environment filter if provided
      if (environmentId != null && environmentId != 'all') {
        requestBody['parameters']['environment_id'] = environmentId;
      }

      final response = await _apiService.post('${reportsEndpoint}generate', requestBody);
      
      // ignore: unnecessary_null_comparison
      if (response != null && response['id'] != null) {
        return response['id'].toString();
      } else {
        throw Exception('Respuesta inválida del servidor');
      }
    } catch (e) {
      throw Exception('Error generando reporte en el servidor: $e');
    }
  }

  Future<String> downloadReportFromAPI(String reportId) async {
    try {
      // This would typically download the file from the backend
      // For now, we'll return a placeholder path
      final response = await _apiService.get('${reportsEndpoint}$reportId/download');
      
      if (response != null) {
        // In a real implementation, this would handle the file download
        return 'downloaded_report_$reportId';
      } else {
        throw Exception('No se pudo descargar el reporte');
      }
    } catch (e) {
      throw Exception('Error descargando reporte: $e');
    }
  }

  Future<List<EnvironmentModel>> getEnvironments() async {
    try {
      final environmentsData = await _apiService.get(environmentsEndpoint);
      
      if (environmentsData == null || environmentsData is! List) {
        print('Invalid environments data received');
        return [];
      }
      
      List<EnvironmentModel> environments = [];
      for (var env in environmentsData) {
        try {
          environments.add(EnvironmentModel.fromJson(env));
        } catch (e) {
          print('Error parsing environment: $e');
          // Continue with other environments
        }
      }
      
      return environments;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El archivo se ha guardado exitosamente.'),
            const SizedBox(height: 8),
            if (!kIsWeb && Platform.isLinux) ...[
              const Text('Ubicación:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(
                filePath,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ] else ...[
              Text('Archivo: ${filePath.split('/').last}'),
            ],
          ],
        ),
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
