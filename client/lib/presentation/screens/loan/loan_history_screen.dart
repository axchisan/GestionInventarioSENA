import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  String selectedFilter = 'Todos';
  String selectedPeriod = 'Este mes';
  final List<String> filters = ['Todos', 'Activos', 'Devueltos', 'Vencidos'];
  final List<String> periods = ['Hoy', 'Esta semana', 'Este mes', 'Este año'];

  final List<Map<String, dynamic>> loanHistory = [
    {
      'id': 'PR001',
      'equipment': 'Computador Dell OptiPlex',
      'equipmentId': 'PC001',
      'borrower': 'Juan Pérez',
      'program': 'Técnico en Sistemas',
      'loanDate': '2024-01-15',
      'returnDate': '2024-01-17',
      'actualReturnDate': '2024-01-17',
      'status': 'Devuelto',
      'condition': 'Bueno',
      'supervisor': 'Ana García',
    },
    {
      'id': 'PR002',
      'equipment': 'Proyector Epson',
      'equipmentId': 'PRJ001',
      'borrower': 'María López',
      'program': 'Análisis y Desarrollo',
      'loanDate': '2024-01-14',
      'returnDate': '2024-01-16',
      'actualReturnDate': null,
      'status': 'Activo',
      'condition': 'Excelente',
      'supervisor': 'Carlos Rodríguez',
    },
    {
      'id': 'PR003',
      'equipment': 'Tablet Samsung',
      'equipmentId': 'TAB001',
      'borrower': 'Pedro Sánchez',
      'program': 'Técnico en Sistemas',
      'loanDate': '2024-01-12',
      'returnDate': '2024-01-14',
      'actualReturnDate': null,
      'status': 'Vencido',
      'condition': 'Bueno',
      'supervisor': 'Ana García',
    },
    {
      'id': 'PR004',
      'equipment': 'Cámara Canon',
      'equipmentId': 'CAM001',
      'borrower': 'Laura Martínez',
      'program': 'Diseño Gráfico',
      'loanDate': '2024-01-10',
      'returnDate': '2024-01-12',
      'actualReturnDate': '2024-01-11',
      'status': 'Devuelto',
      'condition': 'Excelente',
      'supervisor': 'Luis Hernández',
    },
    {
      'id': 'PR005',
      'equipment': 'Monitor Samsung 24"',
      'equipmentId': 'MON001',
      'borrower': 'Diego Torres',
      'program': 'Análisis y Desarrollo',
      'loanDate': '2024-01-08',
      'returnDate': '2024-01-10',
      'actualReturnDate': '2024-01-10',
      'status': 'Devuelto',
      'condition': 'Bueno',
      'supervisor': 'Carlos Rodríguez',
    },
  ];

  List<Map<String, dynamic>> get filteredLoans {
    List<Map<String, dynamic>> filtered = loanHistory;
    
    if (selectedFilter != 'Todos') {
      filtered = filtered.where((loan) => loan['status'] == selectedFilter).toList();
    }
    
    // Aquí se podría agregar filtrado por período
    
    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.blue;
      case 'devuelto':
        return Colors.green;
      case 'vencido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int getDaysOverdue(String returnDate) {
    final return_date = DateTime.parse(returnDate);
    final now = DateTime.now();
    return now.difference(return_date).inDays;
  }

  StatusType _getStatusType(String? status) {
    switch (status?.toLowerCase()) {
      case 'activo':
        return StatusType.primary;
      case 'devuelto':
        return StatusType.success;
      case 'vencido':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    
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
                    const Expanded(
                      child: Text(
                        'Resumen de Préstamos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatChip('Total', stats['total'].toString(), Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Activos', stats['active'].toString(), Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Vencidos', stats['overdue'].toString(), Colors.red)),
                  ],
                ),
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
                      },
                      underline: Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de préstamos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLoans.length,
              itemBuilder: (context, index) {
                final loan = filteredLoans[index];
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
                                    loan['equipment'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${loan['equipmentId']} • ${loan['id']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              text: loan['status'],
                              type: _getStatusType(loan['status']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                loan['borrower'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.school_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              loan['program'],
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
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
                                    'Fecha de préstamo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    loan['loanDate'],
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
                                    loan['returnDate'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: loan['status'] == 'Vencido' ? Colors.red : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (loan['actualReturnDate'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Devuelto el ${loan['actualReturnDate']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        if (loan['status'] == 'Vencido') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.warning_outlined, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                'Vencido hace ${getDaysOverdue(loan['returnDate'])} días',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.supervisor_account_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Supervisor: ${loan['supervisor']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
            style: TextStyle(
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

  Map<String, int> _calculateStats() {
    return {
      'total': loanHistory.length,
      'active': loanHistory.where((loan) => loan['status'] == 'Activo').length,
      'overdue': loanHistory.where((loan) => loan['status'] == 'Vencido').length,
      'returned': loanHistory.where((loan) => loan['status'] == 'Devuelto').length,
    };
  }
}