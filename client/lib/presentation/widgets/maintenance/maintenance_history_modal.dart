import 'package:flutter/material.dart';
import '../../../data/models/maintenance_request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/services/session_service.dart';
import '../common/sena_card.dart';
import '../common/status_badge.dart';

class MaintenanceHistoryModal extends StatefulWidget {
  final String? userId; // If null, shows all requests for admin/supervisor
  final String title;

  const MaintenanceHistoryModal({
    Key? key,
    this.userId,
    this.title = 'Historial de Solicitudes de Mantenimiento',
  }) : super(key: key);

  @override
  State<MaintenanceHistoryModal> createState() => _MaintenanceHistoryModalState();
}

class _MaintenanceHistoryModalState extends State<MaintenanceHistoryModal> {
  List<MaintenanceRequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Pendiente', 'Asignado', 'En Progreso', 'Completado', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRequests();
  }

  Future<void> _loadMaintenanceRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await MaintenanceService.getMaintenanceRequests();
      final currentUser = await SessionService.getUser();
      
      List<MaintenanceRequestModel> filteredRequests = requests
          .map((json) => MaintenanceRequestModel.fromJson(json))
          .toList();

      // Filter by user if specified
      if (widget.userId != null) {
        filteredRequests = filteredRequests
            .where((request) => request.userId == widget.userId)
            .toList();
      } else if (currentUser != null && currentUser['role'] == 'instructor') {
        // If no userId specified but user is instructor, show only their requests
        filteredRequests = filteredRequests
            .where((request) => request.userId == currentUser['id'])
            .toList();
      }

      // Sort by creation date (newest first)
      filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _requests = filteredRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el historial: $e';
        _isLoading = false;
      });
    }
  }

  List<MaintenanceRequestModel> get _filteredRequests {
    if (_selectedFilter == 'Todas') return _requests;
    
    final statusFilter = _getStatusFromFilter(_selectedFilter);
    return _requests.where((request) => request.status.toLowerCase() == statusFilter).toList();
  }

  String _getStatusFromFilter(String filter) {
    switch (filter) {
      case 'Pendiente':
        return 'pending';
      case 'Asignado':
        return 'assigned';
      case 'En Progreso':
        return 'in_progress';
      case 'Completado':
        return 'completed';
      case 'Cancelado':
        return 'cancelled';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_filteredRequests.length} solicitudes encontradas',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadMaintenanceRequests,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando historial...'),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.error),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadMaintenanceRequests,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _filteredRequests.isEmpty
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
                                    'No hay solicitudes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFilter == 'Todas'
                                        ? 'No se encontraron solicitudes de mantenimiento'
                                        : 'No hay solicitudes con estado: $_selectedFilter',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = _filteredRequests[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRequestCard(request),
                                );
                              },
                            ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(MaintenanceRequestModel request) {
    return SenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(request.status),
                  color: _getStatusColor(request.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${request.id.substring(0, 8)}...',
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                text: request.statusDisplayName,
                type: _getStatusType(request.status),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            request.description,
            style: TextStyle(
              color: AppColors.grey700,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(request.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.priorityDisplayName,
                  style: TextStyle(
                    color: _getPriorityColor(request.priority),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (request.category != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.categoryDisplayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const Spacer(),
              if (request.location != null) ...[
                Icon(Icons.location_on, size: 14, color: AppColors.grey600),
                const SizedBox(width: 4),
                Text(
                  request.location!,
                  style: TextStyle(color: AppColors.grey600, fontSize: 12),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: AppColors.grey600),
              const SizedBox(width: 4),
              Text(
                'Creado: ${_formatDate(request.createdAt)}',
                style: TextStyle(color: AppColors.grey600, fontSize: 12),
              ),
              const Spacer(),
              if (request.cost != null) ...[
                Icon(Icons.attach_money, size: 14, color: AppColors.grey600),
                const SizedBox(width: 4),
                Text(
                  '\$${request.cost!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          
          if (request.actualCompletion != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Completado: ${_formatDate(request.actualCompletion!)}',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.notes!,
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'assigned':
        return AppColors.info;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  StatusType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusType.warning;
      case 'assigned':
        return StatusType.info;
      case 'in_progress':
        return StatusType.primary;
      case 'completed':
        return StatusType.success;
      case 'cancelled':
        return StatusType.error;
      default:
        return StatusType.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
      case 'baja':
        return AppColors.success;
      case 'medium':
      case 'media':
        return AppColors.info;
      case 'high':
      case 'alta':
        return AppColors.warning;
      case 'urgent':
      case 'urgente':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
