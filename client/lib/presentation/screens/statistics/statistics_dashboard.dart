import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../data/models/inventory_check_model.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/maintenance_request_model.dart';
import '../../../data/models/environment_model.dart';

class StatisticsDashboard extends StatefulWidget {
  const StatisticsDashboard({super.key});

  @override
  State<StatisticsDashboard> createState() => _StatisticsDashboardState();
}

class _StatisticsDashboardState extends State<StatisticsDashboard> {
  String _selectedPeriod = 'Último mes';
  
  bool isLoading = true;
  late ApiService _apiService;
  String? userRole;
  
  // Datos estadísticos
  Map<String, dynamic> inventoryStats = {};
  Map<String, dynamic> loanStats = {};
  Map<String, dynamic> maintenanceStats = {};
  Map<String, dynamic> checkStats = {};
  Map<String, dynamic> userStats = {};
  Map<String, dynamic> environmentStats = {};
  List<Map<String, dynamic>> monthlyLoans = [];
  List<Map<String, dynamic>> categoryDistribution = [];
  List<Map<String, dynamic>> topItems = [];

  final Map<String, Map<String, dynamic>> roleBasedContent = {
    'supervisor': {
      'title': 'Panel de Supervisor',
      'description': 'Verificaciones, mantenimiento y auditorías',
      'primaryMetrics': ['checkStats', 'maintenanceStats'],
      'charts': ['monthlyChecks', 'maintenanceByPriority'],
      'sections': ['verification_summary', 'maintenance_overview', 'environment_status'],
    },
    'admin': {
      'title': 'Panel de Administrador de Almacén',
      'description': 'Préstamos, inventario y alertas de almacén',
      'primaryMetrics': ['loanStats', 'inventoryStats'],
      'charts': ['monthlyLoans', 'categoryDistribution'],
      'sections': ['loan_management', 'inventory_overview', 'alerts_monitoring'],
    },
    'admin_general': {
      'title': 'Panel de Administrador General',
      'description': 'Vista completa del sistema',
      'primaryMetrics': ['userStats', 'loanStats', 'inventoryStats', 'maintenanceStats'],
      'charts': ['monthlyLoans', 'categoryDistribution', 'userActivity'],
      'sections': ['system_overview', 'user_management', 'complete_statistics'],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadStatistics();
  }

  void _initializeServices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _apiService = ApiService(authProvider: authProvider);
    userRole = authProvider.currentUser?.role;
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => isLoading = true);
      
      // Calcular fechas según el período seleccionado
      DateTime endDate = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case 'Última semana':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'Último mes':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case 'Últimos 3 meses':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        case 'Último año':
          startDate = endDate.subtract(const Duration(days: 365));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 30));
      }

      Map<String, String> queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      };

      List<Future> futures = [];
      
      // Common data for all roles
      futures.addAll([
        _loadInventoryStatistics(queryParams),
        _loadLoanStatistics(queryParams),
        _loadMaintenanceStatistics(queryParams),
        _loadCheckStatistics(queryParams),
      ]);

      // Role-specific data
      if (userRole == 'admin_general') {
        futures.addAll([
          _loadUserStatistics(queryParams),
          _loadEnvironmentStatistics(queryParams),
          _loadMonthlyLoanData(queryParams),
          _loadCategoryDistribution(),
          _loadTopItems(queryParams),
        ]);
      } else if (userRole == 'admin') {
        futures.addAll([
          _loadMonthlyLoanData(queryParams),
          _loadCategoryDistribution(),
          _loadTopItems(queryParams),
        ]);
      } else if (userRole == 'supervisor') {
        futures.addAll([
          _loadEnvironmentStatistics(queryParams),
          _loadMonthlyCheckData(queryParams), // This should be _loadMonthlyCheckData for supervisor
        ]);
      }

      final results = await Future.wait(futures);
      
      setState(() {
        inventoryStats = results[0] as Map<String, dynamic>;
        loanStats = results[1] as Map<String, dynamic>;
        maintenanceStats = results[2] as Map<String, dynamic>;
        checkStats = results[3] as Map<String, dynamic>;
        
        int resultIndex = 4;
        if (userRole == 'admin_general') {
          userStats = results[resultIndex++] as Map<String, dynamic>;
          environmentStats = results[resultIndex++] as Map<String, dynamic>;
          monthlyLoans = results[resultIndex++] as List<Map<String, dynamic>>;
          categoryDistribution = results[resultIndex++] as List<Map<String, dynamic>>;
          topItems = results[resultIndex++] as List<Map<String, dynamic>>;
        } else if (userRole == 'admin') {
          monthlyLoans = results[resultIndex++] as List<Map<String, dynamic>>;
          categoryDistribution = results[resultIndex++] as List<Map<String, dynamic>>;
          topItems = results[resultIndex++] as List<Map<String, dynamic>>;
        } else if (userRole == 'supervisor') {
          environmentStats = results[resultIndex++] as Map<String, dynamic>;
          monthlyLoans = results[resultIndex++] as List<Map<String, dynamic>>; // Actually monthly checks for supervisor
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadInventoryStatistics(Map<String, String> queryParams) async {
    try {
      final inventoryData = await _apiService.get(inventoryEndpoint, queryParams: queryParams);
      
      if (inventoryData == null || inventoryData is! List) {
        return {};
      }
      
      List<InventoryItemModel> items = [];
      for (var item in inventoryData) {
        try {
          items.add(InventoryItemModel.fromJson(item));
        } catch (e) {
          print('Error parsing inventory item: $e');
        }
      }

      return {
        'total_items': items.length,
        'available_items': items.where((i) => i.status == 'available').length,
        'damaged_items': items.where((i) => i.status == 'damaged').length,
        'missing_items': items.where((i) => i.status == 'missing').length,
        'in_maintenance': items.where((i) => i.status == 'maintenance').length,
        'needs_maintenance': items.where((i) => i.needsMaintenance).length,
      };
    } catch (e) {
      print('Error loading inventory statistics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadLoanStatistics(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      
      if (loansData == null) {
        return {
          'total_loans': 0,
          'active_loans': 0,
          'pending_loans': 0,
          'overdue_loans': 0,
          'returned_loans': 0,
          'average_days': 0,
          'satisfaction_rate': 4.8,
        };
      }
      
      // If API returns a Map (statistics), use it directly
      if (loansData is Map<String, dynamic>) {
        return {
          'total_loans': loansData['total_loans'] ?? 0,
          'active_loans': loansData['active_loans'] ?? 0,
          'pending_loans': loansData['pending_loans'] ?? 0,
          'overdue_loans': loansData['overdue_loans'] ?? 0,
          'returned_loans': loansData['returned_loans'] ?? 0,
          'average_days': loansData['average_days'] ?? 0,
          'satisfaction_rate': loansData['satisfaction_rate'] ?? 4.8,
        };
      }
      
      // If API returns a List, process it to calculate statistics
      if (loansData is List) {
        List<LoanModel> loans = [];
        for (var loan in loansData) {
          try {
            loans.add(LoanModel.fromJson(loan));
          } catch (e) {
            print('Error parsing loan: $e');
          }
        }

        // Calcular tiempo promedio de préstamo
        double averageDays = 0;
        int completedLoans = 0;
        
        for (var loan in loans) {
          if (loan.actualReturnDate != null) {
            DateTime returnDate = DateTime.parse(loan.actualReturnDate!);
            DateTime startDate = DateTime.parse(loan.startDate);
            int days = returnDate.difference(startDate).inDays;
            averageDays += days;
            completedLoans++;
          }
        }
        
        if (completedLoans > 0) {
          averageDays = averageDays / completedLoans;
        }

        return {
          'total_loans': loans.length,
          'active_loans': loans.where((l) => l.status == 'active').length,
          'pending_loans': loans.where((l) => l.status == 'pending').length,
          'overdue_loans': loans.where((l) => l.status == 'overdue').length,
          'returned_loans': loans.where((l) => l.status == 'returned').length,
          'average_days': averageDays.round(),
          'satisfaction_rate': 4.8,
        };
      }
      
      // Fallback for unexpected data types
      return {
        'total_loans': 0,
        'active_loans': 0,
        'pending_loans': 0,
        'overdue_loans': 0,
        'returned_loans': 0,
        'average_days': 0,
        'satisfaction_rate': 4.8,
      };
    } catch (e) {
      print('Error loading loan statistics: $e');
      return {
        'total_loans': 0,
        'active_loans': 0,
        'pending_loans': 0,
        'overdue_loans': 0,
        'returned_loans': 0,
        'average_days': 0,
        'satisfaction_rate': 4.8,
      };
    }
  }

  Future<Map<String, dynamic>> _loadMaintenanceStatistics(Map<String, String> queryParams) async {
    try {
      final maintenanceData = await _apiService.get(maintenanceRequestsEndpoint, queryParams: queryParams);
      
      if (maintenanceData == null) {
        return {
          'total_requests': 0,
          'pending_requests': 0,
          'in_progress_requests': 0,
          'completed_requests': 0,
          'total_cost': 0.0,
          'urgent_requests': 0,
        };
      }
      
      // If API returns a Map (statistics), use it directly
      if (maintenanceData is Map<String, dynamic>) {
        return {
          'total_requests': maintenanceData['total_requests'] ?? 0,
          'pending_requests': maintenanceData['pending_requests'] ?? 0,
          'in_progress_requests': maintenanceData['in_progress_requests'] ?? 0,
          'completed_requests': maintenanceData['completed_requests'] ?? 0,
          'total_cost': (maintenanceData['total_cost'] ?? 0.0).toDouble(),
          'urgent_requests': maintenanceData['urgent_requests'] ?? 0,
        };
      }
      
      // If API returns a List, process it to calculate statistics
      if (maintenanceData is List) {
        List<MaintenanceRequestModel> requests = [];
        for (var req in maintenanceData) {
          try {
            requests.add(MaintenanceRequestModel.fromJson(req));
          } catch (e) {
            print('Error parsing maintenance request: $e');
          }
        }

        double totalCost = requests
            .where((r) => r.cost != null)
            .fold(0.0, (sum, r) => sum + r.cost!);

        return {
          'total_requests': requests.length,
          'pending_requests': requests.where((r) => r.status == 'pending').length,
          'in_progress_requests': requests.where((r) => r.status == 'in_progress').length,
          'completed_requests': requests.where((r) => r.status == 'completed').length,
          'total_cost': totalCost,
          'urgent_requests': requests.where((r) => r.priority == 'urgent' || r.priority == 'urgente').length,
        };
      }
      
      // Fallback for unexpected data types
      return {
        'total_requests': 0,
        'pending_requests': 0,
        'in_progress_requests': 0,
        'completed_requests': 0,
        'total_cost': 0.0,
        'urgent_requests': 0,
      };
    } catch (e) {
      print('Error loading maintenance statistics: $e');
      return {
        'total_requests': 0,
        'pending_requests': 0,
        'in_progress_requests': 0,
        'completed_requests': 0,
        'total_cost': 0.0,
        'urgent_requests': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadCheckStatistics(Map<String, String> queryParams) async {
    try {
      final checksData = await _apiService.get(inventoryChecksEndpoint, queryParams: queryParams);
      
      if (checksData == null || checksData is! List) {
        return {};
      }
      
      List<InventoryCheckModel> checks = [];
      for (var check in checksData) {
        try {
          checks.add(InventoryCheckModel.fromJson(check));
        } catch (e) {
          print('Error parsing inventory check: $e');
        }
      }

      int completedChecks = checks.where((c) => c.isComplete).length;
      double complianceRate = checks.isNotEmpty ? (completedChecks / checks.length * 100) : 0;

      return {
        'total_checks': checks.length,
        'completed_checks': completedChecks,
        'checks_with_issues': checks.where((c) => c.hasIssues).length,
        'compliance_rate': complianceRate.round(),
        'pending_checks': checks.where((c) => c.status == 'student_pending').length,
      };
    } catch (e) {
      print('Error loading check statistics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadUserStatistics(Map<String, String> queryParams) async {
    try {
      final usersData = await _apiService.get('/api/users', queryParams: queryParams);
      
      if (usersData == null) {
        return {
          'total_users': 0,
          'active_users': 0,
          'students': 0,
          'instructors': 0,
          'admins': 0,
        };
      }

      // If API returns a Map (statistics), use it directly
      if (usersData is Map<String, dynamic>) {
        return {
          'total_users': usersData['total_users'] ?? 0,
          'active_users': usersData['active_users'] ?? 0,
          'students': usersData['students'] ?? 0,
          'instructors': usersData['instructors'] ?? 0,
          'admins': usersData['admins'] ?? 0,
        };
      }

      // If API returns a List, process it to calculate statistics
      if (usersData is List) {
        return {
          'total_users': usersData.length,
          'active_users': usersData.where((u) => u['is_active'] == true).length,
          'students': usersData.where((u) => u['role'] == 'student').length,
          'instructors': usersData.where((u) => u['role'] == 'instructor').length,
          'admins': usersData.where((u) => u['role']?.contains('admin') == true).length,
        };
      }
      
      // Fallback for unexpected data types
      return {
        'total_users': 0,
        'active_users': 0,
        'students': 0,
        'instructors': 0,
        'admins': 0,
      };
    } catch (e) {
      print('Error loading user statistics: $e');
      return {
        'total_users': 0,
        'active_users': 0,
        'students': 0,
        'instructors': 0,
        'admins': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadEnvironmentStatistics(Map<String, String> queryParams) async {
    try {
      final environmentsData = await _apiService.get(environmentsEndpoint);
      
      if (environmentsData == null || environmentsData is! List) {
        return {};
      }

      List<EnvironmentModel> environments = [];
      for (var env in environmentsData) {
        try {
          environments.add(EnvironmentModel.fromJson(env));
        } catch (e) {
          print('Error parsing environment: $e');
        }
      }

      return {
        'total_environments': environments.length,
        'active_environments': environments.where((e) => e.isActive).length,
        'warehouses': environments.where((e) => e.isWarehouse).length,
        'classrooms': environments.where((e) => !e.isWarehouse).length,
      };
    } catch (e) {
      print('Error loading environment statistics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadMonthlyLoanData(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      
      if (loansData == null) {
        return _generateEmptyMonthlyData();
      }
      
      // If API returns a Map with monthly data, use it directly
      if (loansData is Map<String, dynamic> && loansData.containsKey('monthly_data')) {
        final monthlyData = loansData['monthly_data'];
        if (monthlyData is List) {
          return List<Map<String, dynamic>>.from(monthlyData);
        }
      }
      
      // If API returns a List of loans, process it to calculate monthly data
      if (loansData is List) {
        List<LoanModel> loans = [];
        for (var loan in loansData) {
          try {
            loans.add(LoanModel.fromJson(loan));
          } catch (e) {
            print('Error parsing loan for monthly data: $e');
          }
        }

        // Agrupar préstamos por mes
        Map<int, int> monthlyCount = {};
        DateTime now = DateTime.now();
        
        for (int i = 5; i >= 0; i--) {
          DateTime monthDate = DateTime(now.year, now.month - i, 1);
          monthlyCount[monthDate.month] = 0;
        }

        for (var loan in loans) {
          DateTime startDate = DateTime.parse(loan.startDate);
          int month = startDate.month;
          if (monthlyCount.containsKey(month)) {
            monthlyCount[month] = monthlyCount[month]! + 1;
          }
        }

        List<String> monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

        return monthlyCount.entries.map((entry) => {
          'month': monthNames[entry.key - 1],
          'count': entry.value,
        }).toList();
      }
      
      // Fallback for unexpected data types
      return _generateEmptyMonthlyData();
    } catch (e) {
      print('Error loading monthly loan data: $e');
      return _generateEmptyMonthlyData();
    }
  }

  Future<List<Map<String, dynamic>>> _loadMonthlyCheckData(Map<String, String> queryParams) async {
    try {
      final checksData = await _apiService.get(inventoryChecksEndpoint, queryParams: queryParams);
      
      if (checksData == null || checksData is! List) {
        return [];
      }
      
      List<InventoryCheckModel> checks = [];
      for (var check in checksData) {
        try {
          checks.add(InventoryCheckModel.fromJson(check));
        } catch (e) {
          print('Error parsing check for monthly data: $e');
        }
      }

      Map<int, int> monthlyCount = {};
      DateTime now = DateTime.now();
      
      for (int i = 5; i >= 0; i--) {
        DateTime monthDate = DateTime(now.year, now.month - i, 1);
        monthlyCount[monthDate.month] = 0;
      }

      for (var check in checks) {
        int month = check.checkDate.month;
        if (monthlyCount.containsKey(month)) {
          monthlyCount[month] = monthlyCount[month]! + 1;
        }
      }

      List<String> monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                                'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

      return monthlyCount.entries.map((entry) => {
        'month': monthNames[entry.key - 1],
        'count': entry.value,
      }).toList();
    } catch (e) {
      print('Error loading monthly check data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategoryDistribution() async {
    try {
      final inventoryData = await _apiService.get(inventoryEndpoint);
      
      if (inventoryData == null) {
        return [];
      }
      
      // If API returns a Map with category distribution, use it directly
      if (inventoryData is Map<String, dynamic> && inventoryData.containsKey('category_distribution')) {
        final categoryData = inventoryData['category_distribution'];
        if (categoryData is List) {
          return List<Map<String, dynamic>>.from(categoryData);
        }
      }
      
      // If API returns a List of inventory items, process it to calculate distribution
      if (inventoryData is List) {
        List<InventoryItemModel> items = [];
        for (var item in inventoryData) {
          try {
            items.add(InventoryItemModel.fromJson(item));
          } catch (e) {
            print('Error parsing item for category distribution: $e');
          }
        }

        Map<String, int> categoryCount = {};
        for (var item in items) {
          String category = item.categoryDisplayName;
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }

        int total = items.length;
        return categoryCount.entries.map((entry) => {
          'category': entry.key,
          'count': entry.value,
          'percentage': total > 0 ? (entry.value / total * 100).round() : 0,
        }).toList();
      }
      
      // Fallback for unexpected data types
      return [];
    } catch (e) {
      print('Error loading category distribution: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTopItems(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      
      if (loansData == null) {
        return [];
      }
      
      // If API returns a Map with top items data, use it directly
      if (loansData is Map<String, dynamic> && loansData.containsKey('top_items')) {
        final topItemsData = loansData['top_items'];
        if (topItemsData is List) {
          return List<Map<String, dynamic>>.from(topItemsData);
        }
      }
      
      // If API returns a List of loans, process it to calculate top items
      if (loansData is List) {
        List<LoanModel> loans = [];
        for (var loan in loansData) {
          try {
            loans.add(LoanModel.fromJson(loan));
          } catch (e) {
            print('Error parsing loan for top items: $e');
          }
        }

        // Contar préstamos por item
        Map<String, int> itemCount = {};
        for (var loan in loans) {
          String itemName = loan.itemName ?? 'Item desconocido';
          itemCount[itemName] = (itemCount[itemName] ?? 0) + 1;
        }

        // Ordenar y tomar los top 5
        var sortedItems = itemCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return sortedItems.take(5).map((entry) => {
          'name': entry.key,
          'count': entry.value,
        }).toList();
      }
      
      // Fallback for unexpected data types
      return [];
    } catch (e) {
      print('Error loading top items: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _generateEmptyMonthlyData() {
    List<String> monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                              'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    DateTime now = DateTime.now();
    
    List<Map<String, dynamic>> emptyData = [];
    for (int i = 5; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      emptyData.add({
        'month': monthNames[monthDate.month - 1],
        'count': 0,
      });
    }
    
    return emptyData;
  }

  @override
  Widget build(BuildContext context) {
    String title = roleBasedContent[userRole]?['title'] ?? 'Estadísticas y Reportes';
    
    return Scaffold(
      appBar: SenaAppBar(title: title),
      body: isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A651)),
                  SizedBox(height: 16),
                  Text('Cargando estadísticas...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoleIndicator(),
                  const SizedBox(height: 16),
                  
                  // Selector de período
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Período:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPeriod,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                'Última semana',
                                'Último mes',
                                'Últimos 3 meses',
                                'Último año',
                              ].map((period) {
                                return DropdownMenuItem(
                                  value: period,
                                  child: Text(period),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriod = value!;
                                });
                                _loadStatistics();
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _loadStatistics,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Actualizar',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._buildRoleBasedContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleIndicator() {
    if (userRole == null || !roleBasedContent.containsKey(userRole)) {
      return const SizedBox.shrink();
    }
    
    final roleConfig = roleBasedContent[userRole]!;
    Color roleColor = _getRoleColor(userRole!);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getRoleIcon(userRole!),
                color: roleColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleConfig['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    roleConfig['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'supervisor':
        return Colors.blue;
      case 'admin':
        return const Color(0xFF00A651);
      case 'admin_general':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'supervisor':
        return Icons.supervisor_account;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'admin_general':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  List<Widget> _buildRoleBasedContent() {
    if (userRole == null || !roleBasedContent.containsKey(userRole)) {
      return [_buildMetricsSection()];
    }

    List<Widget> widgets = [];
    
    // Always show metrics section
    widgets.add(_buildMetricsSection());
    widgets.add(const SizedBox(height: 24));
    
    // Role-specific charts
    if (userRole == 'supervisor') {
      widgets.add(_buildMonthlyChecksChart());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildEnvironmentStatusSection());
    } else if (userRole == 'admin') {
      widgets.add(_buildMonthlyLoansChart());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildCategoryDistributionChart());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildTopItemsSection());
    } else if (userRole == 'admin_general') {
      widgets.add(_buildMonthlyLoansChart());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildCategoryDistributionChart());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildTopItemsSection());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildUserManagementSection());
    }
    
    return widgets;
  }

  Widget _buildMetricsSection() {
    List<Widget> metricCards = [];
    
    if (userRole == 'supervisor') {
      metricCards.addAll([
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Verificaciones',
                '${checkStats['total_checks'] ?? 0}',
                _calculateChange(checkStats['total_checks'] ?? 0, 50),
                AppColors.primary,
                Icons.fact_check,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cumplimiento',
                '${checkStats['compliance_rate'] ?? 0}%',
                _calculateChange(checkStats['compliance_rate'] ?? 0, 85),
                AppColors.success,
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Mantenimientos',
                '${maintenanceStats['total_requests'] ?? 0}',
                _calculateChange(maintenanceStats['total_requests'] ?? 0, 15),
                AppColors.warning,
                Icons.build,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Ambientes',
                '${environmentStats['total_environments'] ?? 0}',
                _calculateChange(environmentStats['total_environments'] ?? 0, 20),
                AppColors.info,
                Icons.location_on,
              ),
            ),
          ],
        ),
      ]);
    } else if (userRole == 'admin') {
      metricCards.addAll([
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Préstamos Totales',
                '${loanStats['total_loans'] ?? 0}',
                _calculateChange(loanStats['total_loans'] ?? 0, 100),
                AppColors.primary,
                Icons.assignment,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Items Disponibles',
                '${inventoryStats['available_items'] ?? 0}',
                _calculateChange(inventoryStats['available_items'] ?? 0, 80),
                AppColors.secondary,
                Icons.inventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Préstamos Activos',
                '${loanStats['active_loans'] ?? 0}',
                _calculateChange(loanStats['active_loans'] ?? 0, 25),
                AppColors.info,
                Icons.assignment_turned_in,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Items en Mantenimiento',
                '${inventoryStats['in_maintenance'] ?? 0}',
                _calculateChange(inventoryStats['in_maintenance'] ?? 0, 5),
                AppColors.warning,
                Icons.build,
              ),
            ),
          ],
        ),
      ]);
    } else if (userRole == 'admin_general') {
      metricCards.addAll([
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Usuarios Totales',
                '${userStats['total_users'] ?? 0}',
                _calculateChange(userStats['total_users'] ?? 0, 150),
                AppColors.primary,
                Icons.people,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Préstamos Totales',
                '${loanStats['total_loans'] ?? 0}',
                _calculateChange(loanStats['total_loans'] ?? 0, 100),
                AppColors.secondary,
                Icons.assignment,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Items Disponibles',
                '${inventoryStats['available_items'] ?? 0}',
                _calculateChange(inventoryStats['available_items'] ?? 0, 80),
                AppColors.info,
                Icons.inventory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Mantenimientos',
                '${maintenanceStats['total_requests'] ?? 0}',
                _calculateChange(maintenanceStats['total_requests'] ?? 0, 15),
                AppColors.warning,
                Icons.build,
              ),
            ),
          ],
        ),
      ]);
    }
    
    return Column(children: metricCards);
  }

  Widget _buildMonthlyChecksChart() {
    if (monthlyLoans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Verificaciones por Mes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                child: const Center(
                  child: Text('No hay datos disponibles'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    double maxY = monthlyLoans.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY == 0) maxY = 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verificaciones por Mes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyLoans.length) {
                            return Text(monthlyLoans[value.toInt()]['month']);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyLoans.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: Colors.blue,
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de Ambientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentStatusCard(
                    'Total',
                    '${environmentStats['total_environments'] ?? 0}',
                    Icons.location_on,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnvironmentStatusCard(
                    'Activos',
                    '${environmentStats['active_environments'] ?? 0}',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentStatusCard(
                    'Almacenes',
                    '${environmentStats['warehouses'] ?? 0}',
                    Icons.warehouse,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnvironmentStatusCard(
                    'Aulas',
                    '${environmentStats['classrooms'] ?? 0}',
                    Icons.school,
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Usuarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    'Estudiantes',
                    '${userStats['students'] ?? 0}',
                    Icons.school,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserTypeCard(
                    'Instructores',
                    '${userStats['instructors'] ?? 0}',
                    Icons.person,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    'Administradores',
                    '${userStats['admins'] ?? 0}',
                    Icons.admin_panel_settings,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserTypeCard(
                    'Usuarios Activos',
                    '${userStats['active_users'] ?? 0}',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLoansChart() {
    if (monthlyLoans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Préstamos por Mes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                child: const Center(
                  child: Text('No hay datos disponibles'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    double maxY = monthlyLoans.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY == 0) maxY = 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Préstamos por Mes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyLoans.length) {
                            return Text(monthlyLoans[value.toInt()]['month']);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyLoans.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: AppColors.primary,
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart() {
    if (categoryDistribution.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Distribución por Categorías',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                child: const Center(
                  child: Text('No hay datos disponibles'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Color> colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por Categorías',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: categoryDistribution.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> category = entry.value;
                          return PieChartSectionData(
                            value: category['percentage'].toDouble(),
                            title: '${category['percentage']}%',
                            color: colors[index % colors.length],
                            radius: 60,
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: categoryDistribution.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> category = entry.value;
                      return _buildLegendItem(
                        category['category'],
                        colors[index % colors.length],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items Más Prestados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay datos de préstamos disponibles',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...topItems.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                return _buildTopItemRow(
                  item['name'],
                  '${item['count']} préstamos',
                  index + 1,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
  ) {
    final isPositive = change.startsWith('+');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemRow(String name, String count, int position) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: position <= 3 ? AppColors.primary : AppColors.grey300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: position <= 3 ? Colors.white : AppColors.grey600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateChange(dynamic current, dynamic previous) {
    if (current == null || previous == null) return '+0%';
    
    double currentValue = current is int ? current.toDouble() : current;
    double previousValue = previous is int ? previous.toDouble() : previous;
    
    if (previousValue == 0) return '+0%';
    
    double change = ((currentValue - previousValue) / previousValue * 100);
    String sign = change >= 0 ? '+' : '';
    return '$sign${change.round()}%';
  }
}
