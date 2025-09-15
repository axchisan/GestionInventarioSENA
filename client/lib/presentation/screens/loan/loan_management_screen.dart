import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../../data/models/loan_model.dart';

class LoanManagementScreen extends StatefulWidget {
  const LoanManagementScreen({super.key});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = [
    'all',
    'pending',
    'approved',
    'active',
    'overdue',
    'returned',
    'rejected',
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Todos',
    'pending': 'Pendientes',
    'approved': 'Aprobados',
    'active': 'Activos',
    'overdue': 'Vencidos',
    'returned': 'Devueltos',
    'rejected': 'Rechazados',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await Future.wait([
      loanProvider.fetchLoans(
        statusFilter: _selectedFilter == 'all' ? null : _selectedFilter,
      ),
      loanProvider.fetchStats(
        environmentId: authProvider.currentUser?.environmentId,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == 'admin';

    return Scaffold(
      appBar: SenaAppBar(
        title: isAdmin ? 'Gestión de Préstamos' : 'Mis Préstamos',
        actions: [
          if (!isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/loan-request').then((_) {
                  _loadData();
                });
              },
            ),
        ],
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, child) {
          if (loanProvider.isLoading && loanProvider.loans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Statistics Card
                if (loanProvider.stats != null) _buildStatsCard(loanProvider.stats!),
                
                // Filters
                _buildFilters(),
                
                // Loans List
                Expanded(
                  child: loanProvider.loans.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay préstamos para mostrar',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.grey600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: loanProvider.loans.length,
                          itemBuilder: (context, index) {
                            final loan = loanProvider.loans[index];
                            return _buildLoanCard(loan, isAdmin);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(LoanStatsModel stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Préstamos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatChip('Total', stats.totalLoans.toString(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip('Pendientes', stats.pendingLoans.toString(), Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip('Activos', stats.activeLoans.toString(), Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip('Vencidos', stats.overdueLoans.toString(), Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterLabels[filter] ?? filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                _loadData();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SenaCard(
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
                      if (loan.isRegisteredItem && loan.itemDetails != null)
                        Text(
                          'Código: ${loan.itemDetails!['internal_code']}',
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
            
            if (!isAdmin) ...[
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Solicitante: ${loan.instructorName ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            Row(
              children: [
                Icon(Icons.school_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  loan.program,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Propósito: ${loan.purpose}',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
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
                        'Fecha de inicio',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cantidad',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      loan.quantityRequested.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Action buttons for admin
            if (isAdmin && loan.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(loan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveLoan(loan),
                      child: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
            
            // Action buttons for approved loans
            if (isAdmin && loan.isApproved) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _activateLoan(loan),
                child: const Text('Marcar como Entregado'),
              ),
            ],
            
            // Return button for active loans
            if (isAdmin && loan.isActive) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _returnLoan(loan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Marcar como Devuelto'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  StatusType _getStatusType(String status) {
    switch (status) {
      case 'pending':
        return StatusType.warning;
      case 'approved':
        return StatusType.info;
      case 'active':
        return StatusType.primary;
      case 'returned':
        return StatusType.success;
      case 'rejected':
        return StatusType.error;
      case 'overdue':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  Future<void> _approveLoan(LoanModel loan) async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final success = await loanProvider.approveLoan(loan.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo aprobado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loanProvider.errorMessage ?? 'Error al aprobar préstamo'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _activateLoan(LoanModel loan) async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final success = await loanProvider.activateLoan(loan.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo marcado como activo'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loanProvider.errorMessage ?? 'Error al activar préstamo'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _returnLoan(LoanModel loan) async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final success = await loanProvider.returnLoan(loan.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo marcado como devuelto'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loanProvider.errorMessage ?? 'Error al devolver préstamo'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRejectDialog(LoanModel loan) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Préstamo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de que quieres rechazar este préstamo?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                final loanProvider = Provider.of<LoanProvider>(context, listen: false);
                final success = await loanProvider.rejectLoan(loan.id, reasonController.text);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Préstamo rechazado'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loanProvider.errorMessage ?? 'Error al rechazar préstamo'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}
