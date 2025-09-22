import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/audit_service.dart';
import 'package:provider/provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late AuditService _auditService;
  String selectedFilter = 'Todas';
  String selectedUser = 'Todos';
  DateTime? selectedDate;
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<AuditLog> _auditLogs = [];
  AuditStats? _stats;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 20;
  
  final List<String> actionFilters = [
    'Todas', 'LOGIN', 'LOGOUT', 'INVENTORY_CREATE', 'INVENTORY_UPDATE', 
    'INVENTORY_DELETE', 'LOAN_CREATE', 'LOAN_UPDATE', 'MAINTENANCE_CREATE'
  ];
  
  final List<String> users = ['Todos']; // Will be populated from API

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _auditService = AuditService(authProvider: authProvider);
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load stats and initial logs concurrently
      final results = await Future.wait([
        _auditService.getAuditStats(days: 30),
        _auditService.getAuditLogs(page: 1, perPage: _perPage),
      ]);

      final statsData = results[0];
      final logsData = results[1];

      setState(() {
        _stats = AuditStats.fromJson(statsData);
        _auditLogs = (logsData['logs'] as List<dynamic>)
            .map((log) => AuditLog.fromJson(log))
            .toList();
        _currentPage = logsData['page'] ?? 1;
        _totalPages = logsData['total_pages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando datos de auditoría: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String? actionFilter = selectedFilter != 'Todas' ? selectedFilter : null;
      String? startDate = selectedDate?.toIso8601String().split('T')[0];
      String? endDate = selectedDate?.toIso8601String().split('T')[0];

      final logsData = await _auditService.getAuditLogs(
        page: 1,
        perPage: _perPage,
        actionFilter: actionFilter,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _auditLogs = (logsData['logs'] as List<dynamic>)
            .map((log) => AuditLog.fromJson(log))
            .toList();
        _currentPage = logsData['page'] ?? 1;
        _totalPages = logsData['total_pages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error aplicando filtros: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      String? actionFilter = selectedFilter != 'Todas' ? selectedFilter : null;
      String? startDate = selectedDate?.toIso8601String().split('T')[0];
      String? endDate = selectedDate?.toIso8601String().split('T')[0];

      final logsData = await _auditService.getAuditLogs(
        page: _currentPage + 1,
        perPage: _perPage,
        actionFilter: actionFilter,
        startDate: startDate,
        endDate: endDate,
      );

      final newLogs = (logsData['logs'] as List<dynamic>)
          .map((log) => AuditLog.fromJson(log))
          .toList();

      setState(() {
        _auditLogs.addAll(newLogs);
        _currentPage = logsData['page'] ?? _currentPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando más datos: ${e.toString()}')),
      );
    }
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
      case 'loan_create':
      case 'préstamo':
        return Icons.assignment_turned_in_outlined;
      case 'loan_update':
      case 'devolución':
        return Icons.assignment_return_outlined;
      case 'maintenance_create':
      case 'mantenimiento':
        return Icons.build_outlined;
      case 'inventory_create':
      case 'creación':
        return Icons.add_circle_outline;
      case 'inventory_update':
      case 'modificación':
        return Icons.edit_outlined;
      case 'inventory_delete':
      case 'eliminación':
        return Icons.delete_outline;
      case 'login':
        return Icons.login_outlined;
      case 'logout':
        return Icons.logout_outlined;
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

  String _getSeverityFromAction(String action) {
    final auditService = AuditService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    return auditService.getActionSeverity(action);
  }

  String _formatActionForDisplay(String action) {
    final auditService = AuditService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    return auditService.formatActionForDisplay(action);
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
                          'assets/images/sena_logo.png',
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
                    Expanded(child: _buildStatChip('Total', _stats?.totalLogs.toString() ?? '0', Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Hoy', _stats?.todayLogs.toString() ?? '0', Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatChip('Alertas', _stats?.warningLogs.toString() ?? '0', Colors.orange)),
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
                            child: Text(_formatActionForDisplay(filter)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                          });
                          _applyFilters();
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
                          _applyFilters();
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
                            _applyFilters();
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
                          _applyFilters();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (_error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red))),
                  TextButton(
                    onPressed: _loadInitialData,
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            ),

          // Lista de logs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!_isLoadingMore &&
                          scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                          _currentPage < _totalPages) {
                        _loadMoreData();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _auditLogs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _auditLogs.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final log = _auditLogs[index];
                        final severity = _getSeverityFromAction(log.action);
                        
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
                                        color: getSeverityColor(severity).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        getActionIcon(log.action),
                                        color: getSeverityColor(severity),
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
                                              Expanded(
                                                child: Text(
                                                  log.newValues?['description'] ?? 
                                                  _auditService.getLogDescription(log),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              StatusBadge(
                                                text: severity.toUpperCase(),
                                                type: _getSeverityType(severity),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} ${log.createdAt.hour}:${log.createdAt.minute.toString().padLeft(2, '0')}',
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
                                
                                if (log.newValues?['request']?['method'] != null && log.newValues?['request']?['path'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${log.newValues!['request']['method']} ${log.newValues!['request']['path']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                
                                if (log.newValues?['request']?['method'] != null)
                                  const SizedBox(height: 8),
                                
                                Text(
                                  log.newValues?['description'] ?? 
                                  _auditService.getLogDescription(log),
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
                                              Expanded(
                                                child: Text(
                                                  log.userName?.isNotEmpty == true 
                                                    ? log.userName! 
                                                    : (log.userEmail?.isNotEmpty == true 
                                                        ? log.userEmail! 
                                                        : 'Sistema'),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
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
                                                log.ipAddress ?? 'IP desconocida',
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
                                              Expanded(
                                                child: Text(
                                                  _auditService.formatEntityTypeForDisplay(log.entityType),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                log.newValues?['response']?['status_code'] != null 
                                                  ? (log.newValues!['response']['status_code'] >= 200 && log.newValues!['response']['status_code'] < 400
                                                      ? Icons.check_circle_outline 
                                                      : Icons.error_outline)
                                                  : Icons.storage_outlined, 
                                                size: 16, 
                                                color: log.newValues?['response']?['status_code'] != null 
                                                  ? (log.newValues!['response']['status_code'] >= 200 && log.newValues!['response']['status_code'] < 400
                                                      ? Colors.green 
                                                      : Colors.red)
                                                  : Colors.grey[600]
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  log.newValues?['response']?['status_code'] != null 
                                                    ? 'HTTP ${log.newValues!['response']['status_code']}'
                                                    : (log.entityId ?? 'N/A'),
                                                  style: TextStyle(
                                                    color: log.newValues?['response']?['status_code'] != null 
                                                      ? (log.newValues!['response']['status_code'] >= 200 && log.newValues!['response']['status_code'] < 400
                                                          ? Colors.green 
                                                          : Colors.red)
                                                      : Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: log.newValues?['response']?['status_code'] != null 
                                                      ? FontWeight.w500 
                                                      : FontWeight.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (log.newValues?['duration_seconds'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Duración: ${(log.newValues!['duration_seconds'] as num).toStringAsFixed(2)}s',
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
                          ),
                        );
                      },
                    ),
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

  @override
  void dispose() {
    _auditService.dispose();
    super.dispose();
  }
}
