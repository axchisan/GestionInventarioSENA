import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../providers/loan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/loan_model.dart';
import '../../../core/theme/app_colors.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  String selectedFilter = 'Todos';
  String selectedPeriod = 'Este mes';
  final List<String> filters = ['Todos', 'Pendiente', 'Aprobado', 'Activo', 'Devuelto', 'Vencido', 'Rechazado'];
  final List<String> periods = ['Hoy', 'Esta semana', 'Este mes', 'Este año'];
  
  bool _isLoading = true;
  List<LoanModel> _loans = [];
  LoanStatsModel? _stats;

  @override
  void initState() {
    super.initState();
    _loadLoans();
    _loadStats();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      await loanProvider.fetchLoans(
        statusFilter: selectedFilter == 'Todos' ? null : _mapFilterToStatus(selectedFilter),
      );
      
      setState(() {
        _loans = loanProvider.loans;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar préstamos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      await loanProvider.fetchStats();
      
      setState(() {
        _stats = loanProvider.stats;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  String? _mapFilterToStatus(String filter) {
    switch (filter) {
      case 'Pendiente':
        return 'pending';
      case 'Aprobado':
        return 'approved';
      case 'Activo':
        return 'active';
      case 'Devuelto':
        return 'returned';
      case 'Vencido':
        return 'overdue';
      case 'Rechazado':
        return 'rejected';
      default:
        return null;
    }
  }

  List<LoanModel> get filteredLoans {
    List<LoanModel> filtered = _loans;
    
    if (selectedFilter != 'Todos') {
      final statusFilter = _mapFilterToStatus(selectedFilter);
      if (statusFilter != null) {
        filtered = filtered.where((loan) => loan.status == statusFilter).toList();
      }
    }
    
    // TODO: Implementar filtrado por período si es necesario
    
    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'returned':
        return Colors.teal;
      case 'overdue':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  int getDaysOverdue(String returnDate) {
    try {
      final returnDateTime = DateTime.parse(returnDate);
      final now = DateTime.now();
      return now.difference(returnDateTime).inDays;
    } catch (e) {
      return 0;
    }
  }

  StatusType _getStatusType(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return StatusType.warning;
      case 'approved':
        return StatusType.primary;
      case 'active':
        return StatusType.success;
      case 'returned':
        return StatusType.success;
      case 'overdue':
        return StatusType.error;
      case 'rejected':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Historial de Préstamos',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00324D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/sena-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de Préstamos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user?.role == 'instructor')
                            const Text(
                              'Mis solicitudes',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            )
                          else if (user?.role == 'admin')
                            const Text(
                              'Solicitudes de mi almacén',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            )
                          else if (user?.role == 'admin_general')
                            const Text(
                              'Todas las solicitudes del centro',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_stats != null) ...[
                  Row(
                    children: [
                      Expanded(child: _buildStatChip('Total', _stats!.totalLoans.toString(), Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Pendientes', _stats!.pendingLoans.toString(), Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Activos', _stats!.activeLoans.toString(), Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStatChip('Vencidos', _stats!.overdueLoans.toString(), Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Devueltos', _stats!.returnedLoans.toString(), Colors.teal)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Rechazados', _stats!.rejectedLoans.toString(), Colors.grey)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildStatChip('Total', '0', Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Activos', '0', Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip('Vencidos', '0', Colors.red)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters.map((filter) {
                            final isSelected = selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                  _loadLoans();
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: const Color(0xFF00324D),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      items: periods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPeriod = value!;
                        });
                        // TODO: Implementar filtrado por período
                      },
                      underline: Container(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadLoans();
                        _loadStats();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de préstamos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLoans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay préstamos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFilter == 'Todos'
                                  ? 'No se encontraron préstamos'
                                  : 'No hay préstamos con estado: $selectedFilter',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadLoans();
                          await _loadStats();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredLoans.length,
                          itemBuilder: (context, index) {
                            final loan = filteredLoans[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildLoanCard(loan),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    return SenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.isRegisteredItem 
                          ? (loan.itemDetails?['name'] ?? 'Item registrado')
                          : (loan.itemName ?? 'Item personalizado'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ID: ${loan.id.substring(0, 8)}...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                text: loan.statusDisplayName,
                type: _getStatusType(loan.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (loan.instructorName != null) ...[
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    loan.instructorName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  loan.program,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          if (loan.environmentName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Almacén: ${loan.environmentName}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de préstamo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      loan.startDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de devolución',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      loan.endDate,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: loan.isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (loan.actualReturnDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Devuelto el ${loan.actualReturnDate}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          if (loan.isOverdue && loan.actualReturnDate == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Vencido hace ${getDaysOverdue(loan.endDate)} días',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          if (loan.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Motivo: ${loan.rejectionReason}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (loan.adminName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.supervisor_account_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Administrador: ${loan.adminName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.priority_high_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Prioridad: ${loan.priorityDisplayName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'Cantidad: ${loan.quantityRequested}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
