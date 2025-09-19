import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/report_service.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/environment_model.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  String selectedReportType = 'inventory';
  String selectedFormat = 'pdf';
  material.DateTimeRange? selectedDateRange;
  String selectedEnvironment = 'all';
  bool includeImages = false;
  bool includeStatistics = true;
  bool isGenerating = false;
  
  List<EnvironmentModel> environments = [];
  List<Map<String, dynamic>> recentReports = [];
  bool isLoadingData = true;
  late ReportService _reportService;
  String? userRole;

  final List<Map<String, dynamic>> reportTypes = [
    {
      'id': 'inventory',
      'title': 'Reporte de Inventario',
      'description': 'Estado actual de todos los equipos',
      'icon': Icons.inventory_2,
      'roles': ['admin', 'supervisor', 'admin_general'],
    },
    {
      'id': 'loans',
      'title': 'Reporte de Préstamos',
      'description': 'Historial de préstamos y devoluciones',
      'icon': Icons.assignment_return,
      'roles': ['admin', 'supervisor', 'admin_general'],
    },
    {
      'id': 'maintenance',
      'title': 'Reporte de Mantenimiento',
      'description': 'Solicitudes y estado de mantenimientos',
      'icon': Icons.build,
      'roles': ['admin', 'supervisor', 'admin_general'],
    },
    {
      'id': 'audit',
      'title': 'Reporte de Auditoría',
      'description': 'Log de actividades del sistema',
      'icon': Icons.security,
      'roles': ['supervisor', 'admin_general'],
    },
    {
      'id': 'statistics',
      'title': 'Reporte Estadístico',
      'description': 'Análisis y métricas del inventario',
      'icon': Icons.analytics,
      'roles': ['admin', 'supervisor', 'admin_general'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();
  }

  void _initializeServices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService(authProvider: authProvider);
    _reportService = ReportService(apiService);
    userRole = authProvider.currentUser?.role;
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => isLoadingData = true);
      
      final [environmentsResult, recentReportsResult] = await Future.wait([
        _reportService.getEnvironments(),
        _reportService.getRecentReports(),
      ]);
      
      setState(() {
        environments = List<EnvironmentModel>.from(environmentsResult);
        recentReports = List<Map<String, dynamic>>.from(recentReportsResult);
        isLoadingData = false;
      });
    } catch (e) {
      setState(() => isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get availableReportTypes {
    if (userRole == null) return [];
    
    return reportTypes.where((type) {
      List<String> allowedRoles = List<String>.from(type['roles']);
      return allowedRoles.contains(userRole);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return Scaffold(
        appBar: const SenaAppBar(title: 'Generador de Reportes'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00A651)),
              SizedBox(height: 16),
              Text('Cargando datos...'),
            ],
          ),
        ),
      );
    }

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
            ...availableReportTypes.map((type) => _buildReportTypeCard(type)),
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
            
            // Ambiente - Usar ambientes reales de la API
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
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todos los ambientes'),
                      ),
                      ...environments.map((env) => DropdownMenuItem(
                        value: env.id,
                        child: Text(env.displayName),
                      )),
                    ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reportes Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentReports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay reportes recientes',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
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
    final material.DateTimeRange? picked = await material.showDateRangePicker(
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
    
    try {
      DateTimeRange? reportDateRange;
      if (selectedDateRange != null) {
        reportDateRange = DateTimeRange(
          start: selectedDateRange!.start,
          end: selectedDateRange!.end,
        );
      }
      
      final filePath = await _reportService.generateReport(
        reportType: selectedReportType,
        format: selectedFormat,
        dateRange: reportDateRange,
        environmentId: selectedEnvironment == 'all' ? null : selectedEnvironment,
        includeImages: includeImages,
        includeStatistics: includeStatistics,
      );
      
      setState(() => isGenerating = false);
      
      if (mounted) {
        if (!kIsWeb) {
          // Mostrar diálogo con la ruta del archivo en plataformas no web
          _reportService.showFileSavedDialog(context, filePath);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? 'Reporte descargado exitosamente'
                : 'Reporte generado y compartido exitosamente'),
            backgroundColor: const Color(0xFF00A651),
          ),
        );
        
        // Actualizar la lista de reportes recientes
        _loadInitialData();
      }
    } catch (e) {
      setState(() => isGenerating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Descargando ${report['name']}...'),
        backgroundColor: const Color(0xFF00A651),
      ),
    );
    // Aquí puedes implementar la lógica para descargar reportes recientes si están almacenados localmente o en un servidor
  }
}