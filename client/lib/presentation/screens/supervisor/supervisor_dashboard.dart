import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Panel de Supervisor'),
      body: Column(
        children: [
          // Estadísticas rápidas
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.grey100,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStat('Pendientes', '12', AppColors.warning),
                ),
                Expanded(
                  child: _buildQuickStat('Aprobados', '45', AppColors.success),
                ),
                Expanded(
                  child: _buildQuickStat('Rechazados', '3', AppColors.error),
                ),
                Expanded(
                  child: _buildQuickStat('Total', '60', AppColors.primary),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey600,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Préstamos'),
              Tab(text: 'Mantenimiento'),
              Tab(text: 'Usuarios'),
              Tab(text: 'Reportes'),
            ],
          ),
          
          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoansTab(),
                _buildMaintenanceTab(),
                _buildUsersTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansTab() {
    final loans = [
      {
        'id': 'PR-001',
        'user': 'Juan Pérez',
        'item': 'Laptop Dell',
        'date': '2024-01-15',
        'status': 'Pendiente',
        'priority': 'Alta',
      },
      {
        'id': 'PR-002',
        'user': 'María García',
        'item': 'Proyector Epson',
        'date': '2024-01-14',
        'status': 'Aprobado',
        'priority': 'Media',
      },
      {
        'id': 'PR-003',
        'user': 'Carlos López',
        'item': 'Taladro Industrial',
        'date': '2024-01-13',
        'status': 'Rechazado',
        'priority': 'Baja',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _buildLoanCard(loan);
      },
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    Color statusColor;
    switch (loan['status']) {
      case 'Pendiente':
        statusColor = AppColors.warning;
        break;
      case 'Aprobado':
        statusColor = AppColors.success;
        break;
      case 'Rechazado':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey500;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan['item'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Solicitado por: ${loan['user']}',
                        style: const TextStyle(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    loan['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.grey600),
                const SizedBox(width: 4),
                Text(loan['date']),
                const SizedBox(width: 16),
                Icon(Icons.priority_high, size: 16, color: AppColors.grey600),
                const SizedBox(width: 4),
                Text('Prioridad: ${loan['priority']}'),
              ],
            ),
            
            if (loan['status'] == 'Pendiente') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectLoan(loan['id']),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveLoan(loan['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: AppColors.grey400),
          SizedBox(height: 16),
          Text(
            'Solicitudes de Mantenimiento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gestiona las solicitudes de mantenimiento\nde equipos e infraestructura',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage('assets/images/sena_logo.png'), height: 64, width: 64,),
          SizedBox(height: 16),
          Text(
            'Gestión de Usuarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Administra usuarios, permisos\ny roles del sistema',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: AppColors.grey400),
          SizedBox(height: 16),
          Text(
            'Reportes y Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Genera reportes detallados\ny visualiza estadísticas',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  void _approveLoan(String loanId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Préstamo $loanId aprobado'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _rejectLoan(String loanId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Préstamo $loanId rechazado'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
