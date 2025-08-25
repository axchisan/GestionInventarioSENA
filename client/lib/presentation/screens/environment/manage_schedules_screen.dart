import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class ManageSchedulesScreen extends StatefulWidget {
  const ManageSchedulesScreen({super.key});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(authProvider: Provider.of<AuthProvider>(context, listen: false));
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _schedules = await _apiService.get('/api/schedules/', queryParams: {'environment_id': authProvider.currentUser!.environmentId.toString()});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addSchedule() {
    // Show dialog with form for ScheduleCreate
    // Use TextFields for program, ficha, start_time, etc.
    // Then post and refresh
  }

  void _editSchedule(Map<String, dynamic> schedule) {
    // Similar to add, prefill form, then put and refresh
  }

  void _deleteSchedule(String id) async {
    try {
      await _apiService.delete('/api/schedules/$id');
      _fetchSchedules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentUser?.role ?? '';

    return Scaffold(
      appBar: const SenaAppBar(title: 'Gestionar Horarios'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSchedules,
              child: ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule['program'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${schedule['start_time']} - ${schedule['end_time']}'),
                          const SizedBox(height: 8),
                          if (role == 'instructor') ...[
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _editSchedule(schedule),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _deleteSchedule(schedule['id']),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: role == 'instructor' ? FloatingActionButton(
        onPressed: _addSchedule,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}