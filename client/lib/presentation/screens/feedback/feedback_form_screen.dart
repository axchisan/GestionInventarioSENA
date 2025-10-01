import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  late ApiService _apiService;
  
  String selectedCategory = 'suggestion';
  int selectedRating = 5;
  bool isAnonymous = false;
  bool isSubmitting = false;
  bool isLoadingFeedback = true;
  
  List<Map<String, dynamic>> recentFeedback = [];

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'suggestion',
      'title': 'Sugerencia',
      'description': 'Ideas para mejorar la aplicación',
      'icon': Icons.lightbulb_outline,
      'color': Colors.orange,
    },
    {
      'id': 'bug',
      'title': 'Error/Bug',
      'description': 'Reportar un problema técnico',
      'icon': Icons.bug_report,
      'color': Colors.red,
    },
    {
      'id': 'feature',
      'title': 'Nueva Funcionalidad',
      'description': 'Solicitar una nueva característica',
      'icon': Icons.add_circle_outline,
      'color': Colors.blue,
    },
    {
      'id': 'usability',
      'title': 'Usabilidad',
      'description': 'Comentarios sobre la experiencia de uso',
      'icon': Icons.accessibility,
      'color': Colors.purple,
    },
    {
      'id': 'performance',
      'title': 'Rendimiento',
      'description': 'Problemas de velocidad o rendimiento',
      'icon': Icons.speed,
      'color': Colors.teal,
    },
    {
      'id': 'other',
      'title': 'Otro',
      'description': 'Cualquier otro comentario',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _apiService = ApiService(authProvider: authProvider);
    _loadRecentFeedback();
  }

  Future<void> _loadRecentFeedback() async {
    try {
      setState(() => isLoadingFeedback = true);
      
      final feedbackData = await _apiService.get(
        feedbackEndpoint,
        queryParams: {'limit': '5'},
      );
      
      if (feedbackData != null && feedbackData is List) {
        setState(() {
          recentFeedback = feedbackData.map((item) {
            return {
              'id': item['id'],
              'title': item['title'],
              'category': _getCategoryTitle(item['type']),
              'date': _formatDate(item['created_at']),
              'status': _getStatusText(item['status']),
              'rating': item['rating'] ?? 0,
            };
          }).toList();
          isLoadingFeedback = false;
        });
      } else {
        setState(() {
          recentFeedback = [];
          isLoadingFeedback = false;
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      setState(() {
        recentFeedback = [];
        isLoadingFeedback = false;
      });
    }
  }

  String _getCategoryTitle(String type) {
    final category = categories.firstWhere(
      (cat) => cat['id'] == type,
      orElse: () => categories.last,
    );
    return category['title'];
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Enviado';
      case 'reviewed':
        return 'En revisión';
      case 'in_progress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Enviar Comentarios'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildFeedbackForm(),
            const SizedBox(height: 32),
            _buildRecentFeedback(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/sena_logo.png',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Tu opinión es importante!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A651),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ayúdanos a mejorar la aplicación de inventario SENA compartiendo tus comentarios, sugerencias o reportando problemas.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Comentario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Categoría
              const Text(
                'Categoría *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelection(),
              const SizedBox(height: 20),
              
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Resumen breve de tu comentario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  hintText: 'Describe detalladamente tu comentario o sugerencia...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Calificación
              const Text(
                'Calificación general de la aplicación',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildRatingSelector(),
              const SizedBox(height: 20),
              
              // Email (opcional)
              if (!isAnonymous) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email de contacto (opcional)',
                    hintText: 'Para recibir respuesta a tu comentario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Por favor ingresa un email válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Envío anónimo
              CheckboxListTile(
                title: const Text('Enviar de forma anónima'),
                subtitle: const Text('No se solicitará información de contacto'),
                value: isAnonymous,
                onChanged: (value) {
                  setState(() {
                    isAnonymous = value!;
                    if (isAnonymous) {
                      _emailController.clear();
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              
              // Botón enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
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
                            Text('Enviando...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text('Enviar Comentario'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = selectedCategory == category['id'];
        return InkWell(
          onTap: () => setState(() => selectedCategory = category['id']),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? category['color'].withOpacity(0.1)
                  : Colors.grey.shade100,
              border: Border.all(
                color: isSelected 
                    ? category['color']
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'],
                  size: 16,
                  color: isSelected 
                      ? category['color']
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  category['title'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? category['color']
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final rating = index + 1;
          return InkWell(
            onTap: () => setState(() => selectedRating = rating),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.star,
                size: 32,
                color: rating <= selectedRating 
                    ? Colors.amber 
                    : Colors.grey.shade300,
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          _getRatingText(selectedRating),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFeedback() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Comentarios Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoadingFeedback)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recentFeedback.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No has enviado comentarios aún',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentFeedback.map((feedback) => _buildFeedbackItem(feedback)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> feedback) {
    Color statusColor;
    switch (feedback['status']) {
      case 'Resuelto':
        statusColor = Colors.green;
        break;
      case 'En revisión':
        statusColor = Colors.orange;
        break;
      case 'Planificado':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feedback['status'],
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                feedback['category'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                ' • ${feedback['date']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: index < feedback['rating'] 
                        ? Colors.amber 
                        : Colors.grey.shade300,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSubmitting = true);
    
    try {
      final feedbackData = {
        'type': selectedCategory,
        'category': _getCategoryTitle(selectedCategory),
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': 'medium',
        'rating': selectedRating,
        'include_device_info': false,
        'include_logs': false,
        'allow_follow_up': !isAnonymous,
      };

      await _apiService.post(feedbackEndpoint, feedbackData);
      
      setState(() => isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comentario enviado exitosamente! Gracias por tu retroalimentación.'),
            backgroundColor: Color(0xFF00A651),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Limpiar formulario
        _titleController.clear();
        _descriptionController.clear();
        _emailController.clear();
        setState(() {
          selectedCategory = 'suggestion';
          selectedRating = 5;
          isAnonymous = false;
        });
        
        // Reload recent feedback
        _loadRecentFeedback();
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar comentario: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
