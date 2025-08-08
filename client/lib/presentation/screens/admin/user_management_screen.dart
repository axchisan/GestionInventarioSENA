import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedRole = 'Todos';
  String _selectedStatus = 'Todos';

  final List<Map<String, dynamic>> _users = [
    {
      'id': '001',
      'name': 'Carlos Rodríguez',
      'email': 'carlos.rodriguez@sena.edu.co',
      'role': 'Administrador',
      'status': 'Activo',
      'lastLogin': '2024-01-15 09:30',
      'avatar': 'CR',
      'permissions': ['Gestión Completa', 'Reportes', 'Usuarios'],
    },
    {
      'id': '002',
      'name': 'María González',
      'email': 'maria.gonzalez@sena.edu.co',
      'role': 'Supervisor',
      'status': 'Activo',
      'lastLogin': '2024-01-15 08:45',
      'avatar': 'MG',
      'permissions': ['Supervisión', 'Reportes', 'Préstamos'],
    },
    {
      'id': '003',
      'name': 'Juan Pérez',
      'email': 'juan.perez@sena.edu.co',
      'role': 'Instructor',
      'status': 'Inactivo',
      'lastLogin': '2024-01-10 16:20',
      'avatar': 'JP',
      'permissions': ['Consulta', 'Préstamos'],
    },
    {
      'id': '004',
      'name': 'Ana Martínez',
      'email': 'ana.martinez@sena.edu.co',
      'role': 'Aprendiz',
      'status': 'Activo',
      'lastLogin': '2024-01-15 10:15',
      'avatar': 'AM',
      'permissions': ['Consulta'],
    },
  ];

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': '001',
      'name': 'Pedro Silva',
      'email': 'pedro.silva@sena.edu.co',
      'requestedRole': 'Instructor',
      'requestDate': '2024-01-14',
      'avatar': 'PS',
    },
    {
      'id': '002',
      'name': 'Laura Díaz',
      'email': 'laura.diaz@sena.edu.co',
      'requestedRole': 'Supervisor',
      'requestDate': '2024-01-13',
      'avatar': 'LD',
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
      appBar: SenaAppBar(
        title: 'Gestión de Usuarios',
      /*  bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuarios Activos'),
            Tab(text: 'Solicitudes Pendientes'),
          ],
        ), */
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
    final filteredUsers = _users.where((user) {
      final matchesSearch = user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'Todos' || user['role'] == _selectedRole;
      final matchesStatus = _selectedStatus == 'Todos' || user['status'] == _selectedStatus;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildPendingRequestCard(request);
      },
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
                  items: ['Todos', 'Administrador', 'Supervisor', 'Instructor', 'Aprendiz']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
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
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
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
                    user['avatar'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        user['email'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user['status'] == 'Activo' ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['status'],
                    style: TextStyle(
                      color: user['status'] == 'Activo' ? Colors.green[800] : Colors.red[800],
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
                Text('Rol: ${user['role']}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Último acceso: ${user['lastLogin']}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: (user['permissions'] as List<String>).map((permission) {
                return Chip(
                  label: Text(permission, style: const TextStyle(fontSize: 10)),
                  backgroundColor: const Color(0xFF00A651).withOpacity(0.1),
                  labelStyle: const TextStyle(color: Color(0xFF00A651)),
                );
              }).toList(),
            ),
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
                    user['status'] == 'Activo' ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(user['status'] == 'Activo' ? 'Desactivar' : 'Activar'),
                  style: TextButton.styleFrom(
                    foregroundColor: user['status'] == 'Activo' ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
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
                  backgroundColor: Colors.orange,
                  child: Text(
                    request['avatar'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        request['email'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pendiente',
                    style: TextStyle(
                      color: Colors.orange[800],
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
                Text('Rol solicitado: ${request['requestedRole']}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Fecha: ${request['requestDate']}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _rejectRequest(request),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rechazar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveRequest(request),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aprobar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A651)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: ['Administrador', 'Supervisor', 'Instructor', 'Aprendiz']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: null,
            ),
          ],
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
                const SnackBar(content: Text('Usuario agregado exitosamente')),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando usuario: ${user['name']}')),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    setState(() {
      user['status'] = user['status'] == 'Activo' ? 'Inactivo' : 'Activo';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuario ${user['status'].toLowerCase()}')),
    );
  }

  void _approveRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de ${request['name']} aprobada')),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de ${request['name']} rechazada')),
    );
  }
}
