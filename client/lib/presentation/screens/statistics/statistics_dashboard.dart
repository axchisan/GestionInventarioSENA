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
  List<Map<String, dynamic>> monthlyLoans = [];
  List<Map<String, dynamic>> categoryDistribution = [];
  List<Map<String, dynamic>> topItems = [];

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

      // Cargar datos en paralelo
      final results = await Future.wait([
        _loadInventoryStatistics(queryParams),
        _loadLoanStatistics(queryParams),
        _loadMaintenanceStatistics(queryParams),
        _loadCheckStatistics(queryParams),
        _loadMonthlyLoanData(queryParams),
        _loadCategoryDistribution(),
        _loadTopItems(queryParams),
      ]);

      setState(() {
        inventoryStats = results[0] as Map<String, dynamic>;
        loanStats = results[1] as Map<String, dynamic>;
        maintenanceStats = results[2] as Map<String, dynamic>;
        checkStats = results[3] as Map<String, dynamic>;
        monthlyLoans = results[4] as List<Map<String, dynamic>>;
        categoryDistribution = results[5] as List<Map<String, dynamic>>;
        topItems = results[6] as List<Map<String, dynamic>>;
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
      List<InventoryItemModel> items = inventoryData
          .map((item) => InventoryItemModel.fromJson(item))
          .toList();

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
      List<LoanModel> loans = loansData
          .map((loan) => LoanModel.fromJson(loan))
          .toList();

      // Calcular tiempo promedio de préstamo
      double averageDays = 0;
      int completedLoans = 0;
      
      for (var loan in loans) {
        if (loan.actualReturnDate != null) {
          // Parse the actualReturnDate string to DateTime
          DateTime returnDate = DateTime.parse(loan.actualReturnDate!);
          DateTime startDate = DateTime.parse(loan.startDate); // Ensure startDate is also parsed
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
        'satisfaction_rate': 4.8, // Esto podría venir de una encuesta real
      };
    } catch (e) {
      print('Error loading loan statistics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadMaintenanceStatistics(Map<String, String> queryParams) async {
    try {
      final maintenanceData = await _apiService.get(maintenanceRequestsEndpoint, queryParams: queryParams);
      List<MaintenanceRequestModel> requests = maintenanceData
          .map((req) => MaintenanceRequestModel.fromJson(req))
          .toList();

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
    } catch (e) {
      print('Error loading maintenance statistics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadCheckStatistics(Map<String, String> queryParams) async {
    try {
      final checksData = await _apiService.get(inventoryChecksEndpoint, queryParams: queryParams);
      List<InventoryCheckModel> checks = checksData
          .map((check) => InventoryCheckModel.fromJson(check))
          .toList();

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

  Future<List<Map<String, dynamic>>> _loadMonthlyLoanData(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      List<LoanModel> loans = loansData
          .map((loan) => LoanModel.fromJson(loan))
          .toList();

      // Agrupar préstamos por mes
      Map<int, int> monthlyCount = {};
      DateTime now = DateTime.now();
      
      for (int i = 5; i >= 0; i--) {
        DateTime monthDate = DateTime(now.year, now.month - i, 1);
        monthlyCount[monthDate.month] = 0;
      }

      for (var loan in loans) {
        // Parse the startDate string to DateTime
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
    } catch (e) {
      print('Error loading monthly loan data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategoryDistribution() async {
    try {
      final inventoryData = await _apiService.get(inventoryEndpoint);
      List<InventoryItemModel> items = inventoryData
          .map((item) => InventoryItemModel.fromJson(item))
          .toList();

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
    } catch (e) {
      print('Error loading category distribution: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTopItems(Map<String, String> queryParams) async {
    try {
      final loansData = await _apiService.get(loansEndpoint, queryParams: queryParams);
      List<LoanModel> loans = loansData
          .map((loan) => LoanModel.fromJson(loan))
          .toList();

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
    } catch (e) {
      print('Error loading top items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Estadísticas y Reportes'),
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
                  
                  _buildMetricsSection(),
                  const SizedBox(height: 24),
                  
                  _buildMonthlyLoansChart(),
                  const SizedBox(height: 16),
                  
                  _buildCategoryDistributionChart(),
                  const SizedBox(height: 16),
                  
                  _buildTopItemsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      children: [
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
                'Tiempo Promedio',
                '${loanStats['average_days'] ?? 0} días',
                _calculateChange(loanStats['average_days'] ?? 0, 7),
                AppColors.info,
                Icons.schedule,
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
        if (userRole == 'admin' || userRole == 'admin_general') ...[
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
                  'Costo Total',
                  '\$${(maintenanceStats['total_cost'] ?? 0.0).toStringAsFixed(0)}',
                  _calculateChange((maintenanceStats['total_cost'] ?? 0.0).round(), 5000),
                  AppColors.error,
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ],
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