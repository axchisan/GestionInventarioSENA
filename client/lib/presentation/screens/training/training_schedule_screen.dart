import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';

class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScheduleScreen> createState() => _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedProgram = 'Todos';

  final List<Map<String, dynamic>> _trainings = [
    {
      'id': '001',
      'title': 'Manejo Seguro de Herramientas Eléctricas',
      'instructor': 'Carlos Rodríguez',
      'program': 'Electricidad Industrial',
      'date': '2024-01-16',
      'startTime': '08:00',
      'endTime': '10:00',
      'location': 'Laboratorio de Electrónica',
      'capacity': 20,
      'enrolled': 15,
      'status': 'Programada',
      'description': 'Capacitación sobre el uso seguro de herramientas eléctricas y medidas de seguridad.',
      'requirements': ['Overol', 'Gafas de seguridad', 'Guantes dieléctricos'],
    },
    {
      'id': '002',
      'title': 'Soldadura MIG/MAG Básica',
      'instructor': 'María González',
      'program': 'Soldadura',
      'date': '2024-01-16',
      'startTime': '14:00',
      'endTime': '17:00',
      'location': 'Taller de Soldadura',
      'capacity': 12,
      'enrolled': 12,
      'status': 'Completa',
      'description': 'Introducción a las técnicas de soldadura MIG/MAG.',
      'requirements': ['Careta de soldadura', 'Guantes de cuero', 'Delantal'],
    },
    {
      'id': '003',
      'title': 'Mantenimiento Preventivo de Motores',
      'instructor': 'Juan Pérez',
      'program': 'Mecánica Industrial',
      'date': '2024-01-17',
      'startTime': '09:00',
      'endTime': '12:00',
      'location': 'Taller de Mecánica',
      'capacity': 15,
      'enrolled': 8,
      'status': 'Programada',
      'description': 'Técnicas de mantenimiento preventivo para motores industriales.',
      'requirements': ['Overol', 'Herramientas básicas'],
    },
    {
      'id': '004',
      'title': 'Programación de PLC',
      'instructor': 'Ana Martínez',
      'program': 'Automatización',
      'date': '2024-01-18',
      'startTime': '08:00',
      'endTime': '11:00',
      'location': 'Laboratorio de Automatización',
      'capacity': 10,
      'enrolled': 7,
      'status': 'Programada',
      'description': 'Fundamentos de programación de controladores lógicos programables.',
      'requirements': ['Laptop', 'Software específico'],
    },
  ];

  final List<Map<String, dynamic>> _myTrainings = [
    {
      'id': '001',
      'title': 'Manejo Seguro de Herramientas Eléctricas',
      'date': '2024-01-16',
      'startTime': '08:00',
      'status': 'Confirmada',
      'location': 'Laboratorio de Electrónica',
    },
    {
      'id': '003',
      'title': 'Mantenimiento Preventivo de Motores',
      'date': '2024-01-17',
      'startTime': '09:00',
      'status': 'Pendiente',
      'location': 'Taller de Mecánica',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Capacitaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas las Capacitaciones'),
            Tab(text: 'Mis Capacitaciones'),
          ],
        ),
        backgroundColor: const Color(0xFF00A651),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTrainingsTab(),
          _buildMyTrainingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTrainingDialog,
        backgroundColor: const Color(0xFF00A651),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllTrainingsTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _trainings.length,
            itemBuilder: (context, index) {
              final training = _trainings[index];
              return _buildTrainingCard(training);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyTrainingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTrainings.length,
      itemBuilder: (context, index) {
        final training = _myTrainings[index];
        return _buildMyTrainingCard(training);
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProgram,
                  decoration: const InputDecoration(
                    labelText: 'Programa',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Todos', 'Electricidad Industrial', 'Soldadura', 'Mecánica Industrial', 'Automatización']
                      .map((program) => DropdownMenuItem(value: program, child: Text(program)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProgram = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final isAvailable = training['enrolled'] < training['capacity'];
    final statusColor = training['status'] == 'Completa' ? Colors.red : 
                       training['status'] == 'Programada' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    training['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    training['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              training['description'],
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Instructor: ${training['instructor']}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Programa: ${training['program']}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${training['date']} - ${training['startTime']} a ${training['endTime']}', 
                     style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(training['location'], style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: training['enrolled'] / training['capacity'],
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAvailable ? const Color(0xFF00A651) : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${training['enrolled']}/${training['capacity']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Requisitos', style: TextStyle(fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (training['requirements'] as List<String>).map((req) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Color(0xFF00A651)),
                            const SizedBox(width: 8),
                            Text(req, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewTrainingDetails(training),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Detalles'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isAvailable && training['status'] == 'Programada' 
                      ? () => _enrollInTraining(training)
                      : null,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: Text(isAvailable ? 'Inscribirse' : 'Completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTrainingCard(Map<String, dynamic> training) {
    final statusColor = training['status'] == 'Confirmada' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    training['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    training['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${training['date']} - ${training['startTime']}', 
                     style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(training['location'], style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (training['status'] == 'Pendiente')
                  TextButton.icon(
                    onPressed: () => _cancelEnrollment(training),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewTrainingDetails(training),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Ver Detalles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddTrainingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programar Capacitación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Instructor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Programa',
                  border: OutlineInputBorder(),
                ),
                items: const ['Electricidad Industrial', 'Soldadura', 'Mecánica Industrial', 'Automatización']
                    .map((program) => DropdownMenuItem(value: program, child:  Text(program)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Capacidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Capacitación programada exitosamente')),
              );
            },
            child: const Text('Programar'),
          ),
        ],
      ),
    );
  }

  void _viewTrainingDetails(Map<String, dynamic> training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(training['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Instructor: ${training['instructor']}'),
              const SizedBox(height: 8),
              Text('Programa: ${training['program']}'),
              const SizedBox(height: 8),
              Text('Fecha: ${training['date']}'),
              const SizedBox(height: 8),
              Text('Horario: ${training['startTime']} - ${training['endTime']}'),
              const SizedBox(height: 8),
              Text('Ubicación: ${training['location']}'),
              const SizedBox(height: 8),
              Text('Capacidad: ${training['enrolled']}/${training['capacity']}'),
              const SizedBox(height: 12),
              Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(training['description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _enrollInTraining(Map<String, dynamic> training) {
    setState(() {
      training['enrolled']++;
      _myTrainings.add({
        'id': training['id'],
        'title': training['title'],
        'date': training['date'],
        'startTime': training['startTime'],
        'status': 'Pendiente',
        'location': training['location'],
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inscrito en: ${training['title']}')),
    );
  }

  void _cancelEnrollment(Map<String, dynamic> training) {
    setState(() {
      _myTrainings.remove(training);
      // También decrementar el contador en la capacitación original
      final originalTraining = _trainings.firstWhere((t) => t['id'] == training['id']);
      originalTraining['enrolled']--;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inscripción cancelada: ${training['title']}')),
    );
  }
}
