import 'package:flutter/material.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/theme/app_colors.dart';
import '../common/sena_card.dart';

class AlertDetailModal extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onResolve;

  const AlertDetailModal({
    Key? key,
    required this.alert,
    this.onResolve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: alert.priorityColor.withOpacity(0.1),
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
                      color: alert.priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alert.typeIcon,
                      color: alert.priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: alert.priorityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            alert.priorityText,
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
                    // Alert Type and Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Tipo de Alerta',
                            alert.typeText,
                            Icons.category_outlined,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Estado',
                            alert.isResolved ? 'Resuelta' : 'Pendiente',
                            alert.isResolved ? Icons.check_circle : Icons.pending,
                            alert.isResolved ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Message
                    SenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.message_outlined, color: AppColors.grey600),
                              const SizedBox(width: 8),
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Entity Information
                    if (alert.entityType != null && alert.entityId != null) ...[
                      SenaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.grey600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Información Relacionada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'Tipo de Entidad: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey700,
                                  ),
                                ),
                                Text(alert.entityType!),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'ID de Entidad: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey700,
                                  ),
                                ),
                                Text(alert.entityId!),
                              ],
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
                                'Fechas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDateRow('Creada', alert.createdAt),
                          const SizedBox(height: 8),
                          _buildDateRow('Actualizada', alert.updatedAt),
                          if (alert.isResolved && alert.resolvedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildDateRow('Resuelta', alert.resolvedAt!),
                          ],
                        ],
                      ),
                    ),

                    if (alert.isResolved && alert.resolvedBy != null) ...[
                      const SizedBox(height: 16),
                      SenaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, color: AppColors.grey600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Resolución',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'Resuelta por: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey700,
                                  ),
                                ),
                                Text(alert.resolvedBy!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (!alert.isResolved && onResolve != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onResolve!();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        child: const Text('Marcar como Resuelta'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
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

  Widget _buildDateRow(String label, DateTime date) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.grey700,
          ),
        ),
        Text(
          '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }
}
