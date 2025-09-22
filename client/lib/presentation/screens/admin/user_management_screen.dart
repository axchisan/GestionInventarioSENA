import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../../core/services/user_management_service.dart';
import '../../../data/models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final UserManagementService _userService = UserManagementService();
  
  String _searchQuery = '';
  String _selectedRole = 'Todos';
  String _selectedStatus = 'Todos';
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _userService.getUsers(
        role: _selectedRole == 'Todos' ? null : _mapRoleToApi(_selectedRole),
        isActive: _selectedStatus == 'Todos' ? null : _selectedStatus == 'Activo',
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _mapRoleToApi(String displayRole) {
    switch (displayRole) {
      case 'Administrador General': return 'admin_general';
      case 'Administrador': return 'admin';
      case 'Supervisor': return 'supervisor';
      case 'Instructor': return 'instructor';
      case 'Aprendiz': return 'student';
      default: return displayRole.toLowerCase();
    }
  }

  String _mapRoleFromApi(String apiRole) {
    switch (apiRole) {
      case 'admin_general': return 'Administrador General';
      case 'admin': return 'Administrador';
      case 'supervisor': return 'Supervisor';
      case 'instructor': return 'Instructor';
      case 'student': return 'Aprendiz';
      default: return apiRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SenaAppBar(
        title: 'Gestión de Usuarios',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuarios Activos'),
            Tab(text: 'Solicitudes Pendientes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildPendingRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF00A651),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error'),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestsTab() {
    return const Center(
      child: Text(
        'Funcionalidad de solicitudes pendientes\nserá implementada próximamente',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == value) {
                  _loadUsers();
                }
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Todos', 'Administrador General', 'Administrador', 'Supervisor', 'Instructor', 'Aprendiz']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Todos', 'Activo', 'Inactivo']
                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isActive = user.isActive ?? false;
    final displayRole = _mapRoleFromApi(user.role ?? '');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF00A651),
                  child: Text(
                    '${user.firstName?.substring(0, 1) ?? ''}${user.lastName?.substring(0, 1) ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName ?? ''} ${user.lastName ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        user.email ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: isActive ? Colors.green[800] : Colors.red[800],
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
                Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Rol: $displayRole', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                if (user.lastLogin != null) ...[
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Último acceso: ${_formatDate(user.lastLogin!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (user.program != null || user.ficha != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (user.program != null) ...[
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Programa: ${user.program}', style: TextStyle(color: Colors.grey[600])),
                  ],
                  if (user.ficha != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Ficha: ${user.ficha}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editUser(user),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _toggleUserStatus(user),
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(isActive ? 'Desactivar' : 'Activar'),
                  style: TextButton.styleFrom(
                    foregroundColor: isActive ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'email': TextEditingController(),
      'password': TextEditingController(),
      'phone': TextEditingController(),
      'program': TextEditingController(),
      'ficha': TextEditingController(),
    };
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controllers['firstName'],
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['lastName'],
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['email'],
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Campo requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['password'],
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Aprendiz')),
                    DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['phone'],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['program'],
                  decoration: const InputDecoration(
                    labelText: 'Programa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['ficha'],
                  decoration: const InputDecoration(
                    labelText: 'Ficha',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _userService.createUser({
                    'first_name': controllers['firstName']!.text,
                    'last_name': controllers['lastName']!.text,
                    'email': controllers['email']!.text,
                    'password': controllers['password']!.text,
                    'role': selectedRole,
                    'phone': controllers['phone']!.text.isEmpty ? null : controllers['phone']!.text,
                    'program': controllers['program']!.text.isEmpty ? null : controllers['program']!.text,
                    'ficha': controllers['ficha']!.text.isEmpty ? null : controllers['ficha']!.text,
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario creado exitosamente')),
                  );
                  _loadUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _editUser(UserModel user) {
    // TODO: Implement edit user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando usuario: ${user.firstName} ${user.lastName}')),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      final isActive = user.isActive ?? false;
      if (isActive) {
        await _userService.deleteUser(user.id!);
      } else {
        await _userService.activateUser(user.id!);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario ${isActive ? 'desactivado' : 'activado'} exitosamente')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
