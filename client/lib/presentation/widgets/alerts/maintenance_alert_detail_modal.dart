import 'package:flutter/material.dart';
import '../../../data/models/maintenance_request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../common/sena_card.dart';

class MaintenanceAlertDetailModal extends StatelessWidget {
  final MaintenanceRequestModel maintenanceRequest;
  final VoidCallback? onClose;

  const MaintenanceAlertDetailModal({
    Key? key,
    required this.maintenanceRequest,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
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
                      color: _getPriorityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build_outlined,
                      color: _getPriorityColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maintenanceRequest.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            maintenanceRequest.priorityDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Category
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Estado',
                            maintenanceRequest.statusDisplayName,
                            _getStatusIcon(),
                            _getStatusColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Categoría',
                            maintenanceRequest.categoryDisplayName,
                            Icons.category_outlined,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    SenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: AppColors.grey600),
                              const SizedBox(width: 8),
                              const Text(
                                'Descripción del Problema',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            maintenanceRequest.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location and Quantity
                    if (maintenanceRequest.location != null || maintenanceRequest.quantityAffected > 1) ...[
                      Row(
                        children: [
                          if (maintenanceRequest.location != null) ...[
                            Expanded(
                              child: _buildInfoCard(
                                'Ubicación',
                                maintenanceRequest.location!,
                                Icons.location_on_outlined,
                                AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (maintenanceRequest.quantityAffected > 1) ...[
                            Expanded(
                              child: _buildInfoCard(
                                'Cantidad Afectada',
                                '${maintenanceRequest.quantityAffected} unidades',
                                Icons.numbers_outlined,
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Cost and Dates
                    if (maintenanceRequest.cost != null || 
                        maintenanceRequest.estimatedCompletion != null ||
                        maintenanceRequest.actualCompletion != null) ...[
                      SenaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monetization_on_outlined, color: AppColors.grey600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Información Financiera y Fechas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (maintenanceRequest.cost != null) ...[
                              _buildDetailRow('Costo Estimado', '\$${maintenanceRequest.cost!.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                            ],
                            if (maintenanceRequest.estimatedCompletion != null) ...[
                              _buildDetailRow('Fecha Estimada de Finalización', _formatDate(maintenanceRequest.estimatedCompletion!)),
                              const SizedBox(height: 8),
                            ],
                            if (maintenanceRequest.actualCompletion != null) ...[
                              _buildDetailRow('Fecha Real de Finalización', _formatDate(maintenanceRequest.actualCompletion!)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notes
                    if (maintenanceRequest.notes != null && maintenanceRequest.notes!.isNotEmpty) ...[
                      SenaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_outlined, color: AppColors.grey600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notas Adicionales',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              maintenanceRequest.notes!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Images
                    if (maintenanceRequest.imagesUrls != null && maintenanceRequest.imagesUrls!.isNotEmpty) ...[
                      SenaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image_outlined, color: AppColors.grey600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Imágenes del Problema',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: maintenanceRequest.imagesUrls!.map((url) => 
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.grey300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                        Icon(Icons.broken_image, color: AppColors.grey400),
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Timestamps
                    SenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: AppColors.grey600),
                              const SizedBox(width: 8),
                              const Text(
                                'Historial de Fechas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Solicitud Creada', _formatDateTime(maintenanceRequest.createdAt)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Última Actualización', _formatDateTime(maintenanceRequest.updatedAt)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
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

  Color _getPriorityColor() {
    switch (maintenanceRequest.priority.toLowerCase()) {
      case 'urgent':
      case 'urgente':
        return AppColors.error;
      case 'high':
      case 'alta':
        return AppColors.warning;
      case 'medium':
      case 'media':
        return AppColors.info;
      case 'low':
      case 'baja':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  Color _getStatusColor() {
    switch (maintenanceRequest.status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.info;
      case 'assigned':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon() {
    switch (maintenanceRequest.status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.grey700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
