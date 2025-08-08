import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  String selectedReportType = 'inventory';
  String selectedFormat = 'pdf';
  DateTimeRange? selectedDateRange;
  String selectedEnvironment = 'all';
  bool includeImages = false;
  bool includeStatistics = true;
  bool isGenerating = false;

  final List<Map<String, dynamic>> reportTypes = [
    {
      'id': 'inventory',
      'title': 'Reporte de Inventario',
      'description': 'Estado actual de todos los equipos',
      'icon': Icons.inventory_2,
    },
    {
      'id': 'loans',
      'title': 'Reporte de Préstamos',
      'description': 'Historial de préstamos y devoluciones',
      'icon': Icons.assignment_return,
    },
    {
      'id': 'maintenance',
      'title': 'Reporte de Mantenimiento',
      'description': 'Solicitudes y estado de mantenimientos',
      'icon': Icons.build,
    },
    {
      'id': 'audit',
      'title': 'Reporte de Auditoría',
      'description': 'Log de actividades del sistema',
      'icon': Icons.security,
    },
    {
      'id': 'statistics',
      'title': 'Reporte Estadístico',
      'description': 'Análisis y métricas del inventario',
      'icon': Icons.analytics,
    },
  ];

  final List<String> environments = [
    'all',
    'Laboratorio de Sistemas',
    'Taller de Mecánica',
    'Aula de Electrónica',
    'Biblioteca',
    'Oficina Administrativa',
  ];

  final List<Map<String, dynamic>> recentReports = [
    {
      'name': 'Inventario_Enero_2024.pdf',
      'type': 'Inventario',
      'date': '15/01/2024',
      'size': '2.3 MB',
      'status': 'Completado',
    },
    {
      'name': 'Prestamos_Diciembre_2023.xlsx',
      'type': 'Préstamos',
      'date': '28/12/2023',
      'size': '1.8 MB',
      'status': 'Completado',
    },
    {
      'name': 'Mantenimiento_Q4_2023.pdf',
      'type': 'Mantenimiento',
      'date': '20/12/2023',
      'size': '3.1 MB',
      'status': 'Completado',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Generador de Reportes'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportTypeSelection(),
            const SizedBox(height: 24),
            _buildConfigurationSection(),
            const SizedBox(height: 24),
            _buildGenerateButton(),
            const SizedBox(height: 32),
            _buildRecentReports(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/sena_logo.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tipo de Reporte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reportTypes.map((type) => _buildReportTypeCard(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard(Map<String, dynamic> type) {
    final isSelected = selectedReportType == type['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => selectedReportType = type['id']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFF00A651).withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                type['icon'],
                color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF00A651) : null,
                      ),
                    ),
                    Text(
                      type['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00A651),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Reporte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Formato
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Formato:'),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: selectedFormat,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(value: 'excel', child: Text('Excel')),
                      DropdownMenuItem(value: 'csv', child: Text('CSV')),
                    ],
                    onChanged: (value) => setState(() => selectedFormat = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rango de fechas
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Período:'),
                ),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            selectedDateRange != null
                                ? '${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}'
                                : 'Seleccionar período',
                            style: TextStyle(
                              color: selectedDateRange != null ? null : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Ambiente
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Ambiente:'),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: selectedEnvironment,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: environments.map((env) => DropdownMenuItem(
                      value: env,
                      child: Text(env == 'all' ? 'Todos los ambientes' : env),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedEnvironment = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Opciones adicionales
            const Text(
              'Opciones adicionales:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Incluir imágenes'),
              subtitle: const Text('Fotografías de los equipos'),
              value: includeImages,
              onChanged: (value) => setState(() => includeImages = value!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Incluir estadísticas'),
              subtitle: const Text('Gráficos y métricas'),
              value: includeStatistics,
              onChanged: (value) => setState(() => includeStatistics = value!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isGenerating ? null : _generateReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A651),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Generando reporte...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('Generar Reporte'),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentReports.map((report) => _buildRecentReportItem(report)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF00A651),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${report['type']} • ${report['date']} • ${report['size']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report['status'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _downloadReport(report),
            icon: const Icon(Icons.download),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() => selectedDateRange = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _generateReport() async {
    setState(() => isGenerating = true);
    
    // Simular generación de reporte
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() => isGenerating = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte generado exitosamente'),
          backgroundColor: Color(0xFF00A651),
        ),
      );
    }
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Descargando ${report['name']}...'),
        backgroundColor: const Color(0xFF00A651),
      ),
    );
  }
}
