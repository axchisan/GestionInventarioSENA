import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String selectedFilter = 'Todas';
  String selectedUser = 'Todos';
  DateTime? selectedDate;
  
  final List<String> actionFilters = [
    'Todas', 'Préstamo', 'Devolución', 'Mantenimiento', 
    'Creación', 'Modificación', 'Eliminación', 'Login'
  ];
  
  final List<String> users = [
    'Todos', 'Ana García', 'Carlos Rodríguez', 'Luis Martínez', 
    'María López', 'Pedro Sánchez', 'Sistema'
  ];

  final List<Map<String, dynamic>> auditLogs = [
    {
      'id': 'AUD001',
      'timestamp': '2024-01-15 14:30:25',
      'user': 'Ana García',
      'action': 'Préstamo',
      'description': 'Préstamo de Computador Dell OptiPlex (PC001) a Juan Pérez',
      'ipAddress': '192.168.1.100',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'info',
      'module': 'Préstamos',
      'affectedResource': 'PC001',
    },
    {
      'id': 'AUD002',
      'timestamp': '2024-01-15 14:25:10',
      'user': 'Carlos Rodríguez',
      'action': 'Modificación',
      'description': 'Actualización de estado de Proyector Epson (PRJ001) a "Mantenimiento"',
      'ipAddress': '192.168.1.101',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'warning',
      'module': 'Inventario',
      'affectedResource': 'PRJ001',
    },
    {
      'id': 'AUD003',
      'timestamp': '2024-01-15 13:45:33',
      'user': 'Luis Martínez',
      'action': 'Devolución',
      'description': 'Devolución de Tablet Samsung (TAB001) por María López',
      'ipAddress': '192.168.1.102',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'info',
      'module': 'Préstamos',
      'affectedResource': 'TAB001',
    },
    {
      'id': 'AUD004',
      'timestamp': '2024-01-15 12:20:15',
      'user': 'Sistema',
      'action': 'Eliminación',
      'description': 'Eliminación automática de registros de auditoría antiguos (>90 días)',
      'ipAddress': 'localhost',
      'userAgent': 'Sistema Automatizado',
      'severity': 'warning',
      'module': 'Sistema',
      'affectedResource': 'audit_logs',
    },
    {
      'id': 'AUD005',
      'timestamp': '2024-01-15 11:15:42',
      'user': 'María López',
      'action': 'Login',
      'description': 'Inicio de sesión exitoso en el sistema',
      'ipAddress': '192.168.1.103',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'info',
      'module': 'Autenticación',
      'affectedResource': 'user_session',
    },
    {
      'id': 'AUD006',
      'timestamp': '2024-01-15 10:30:18',
      'user': 'Pedro Sánchez',
      'action': 'Creación',
      'description': 'Creación de nuevo equipo: Monitor LG 27" (MON002)',
      'ipAddress': '192.168.1.104',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'info',
      'module': 'Inventario',
      'affectedResource': 'MON002',
    },
    {
      'id': 'AUD007',
      'timestamp': '2024-01-15 09:45:55',
      'user': 'Ana García',
      'action': 'Mantenimiento',
      'description': 'Registro de mantenimiento preventivo para Computador HP (PC002)',
      'ipAddress': '192.168.1.100',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'severity': 'info',
      'module': 'Mantenimiento',
      'affectedResource': 'PC002',
    },
  ];

  List<Map<String, dynamic>> get filteredLogs {
    List<Map<String, dynamic>> filtered = auditLogs;
    
    if (selectedFilter != 'Todas') {
      filtered = filtered.where((log) => log['action'] == selectedFilter).toList();
    }
    
    if (selectedUser != 'Todos') {
      filtered = filtered.where((log) => log['user'] == selectedUser).toList();
    }
    
    if (selectedDate != null) {
      final dateStr = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      filtered = filtered.where((log) => log['timestamp'].startsWith(dateStr)).toList();
    }
    
    return filtered;
  }

  Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'préstamo':
        return Icons.assignment_turned_in_outlined;
      case 'devolución':
        return Icons.assignment_return_outlined;
      case 'mantenimiento':
        return Icons.build_outlined;
      case 'creación':
        return Icons.add_circle_outline;
      case 'modificación':
        return Icons.edit_outlined;
      case 'eliminación':
        return Icons.delete_outline;
      case 'login':
        return Icons.login_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  StatusType _getSeverityType(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'info':
        return StatusType.info;
      case 'warning':
        return StatusType.warning;
      case 'error':
        return StatusType.error;
      case 'success':
        return StatusType.success;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Registro de Auditoría',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Header con logo y estadísticas
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
                        'Registro de Auditoría del Sistema',
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
                    Expanded(child: _buildStatChip('Total', auditLogs.length.toString(), Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Hoy', '${auditLogs.where((log) => log['timestamp'].startsWith('2024-01-15')).length}', Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Alertas', '${auditLogs.where((log) => log['severity'] == 'warning').length}', Colors.orange)),
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
                // Filtros por acción y usuario
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Acción',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: actionFilters.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUser,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: users.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text(user),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedUser = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Filtro por fecha
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate != null 
                                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                  : 'Seleccionar fecha',
                                style: TextStyle(
                                  color: selectedDate != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Lista de logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SenaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: getSeverityColor(log['severity']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                getActionIcon(log['action']),
                                color: getSeverityColor(log['severity']),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log['action'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      StatusBadge(
                                        text: log['severity'].toUpperCase(),
                                        type: _getSeverityType(log['severity']),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    log['timestamp'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          log['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
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
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        log['user'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.computer_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        log['ipAddress'],
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.folder_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        log['module'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.storage_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        log['affectedResource'],
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
}