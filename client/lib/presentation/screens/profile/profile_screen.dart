import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_settings_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiService _apiService;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _idController;
  
  bool _isLoading = true;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _apiService = ApiService(authProvider: authProvider);
    
    final user = authProvider.currentUser;
    _nameController = TextEditingController(text: '${user?.firstName ?? ''} ${user?.lastName ?? ''}');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _idController = TextEditingController(text: user?.id.toString() ?? '');
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user?.environmentId != null) {
        // Load user loan statistics
        final loans = await _apiService.get('/api/loans/', queryParams: {'user_id': user!.id.toString()});
        final activeLoans = loans.where((loan) => loan['status'] == 'active').length;
        final totalLoans = loans.length;
        
        setState(() {
          _userStats = {
            'total_loans': totalLoans,
            'active_loans': activeLoans,
            'completed_loans': totalLoans - activeLoans,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Set default stats if API fails
      setState(() {
        _userStats = {
          'total_loans': 0,
          'active_loans': 0,
          'completed_loans': 0,
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: const SenaAppBar(title: 'Mi Perfil'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Foto de perfil y información básica
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: user?.avatarUrl != null
                                      ? Image.network(
                                          user!.avatarUrl!,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                            'assets/images/sena_logo.png',
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/sena_logo.png',
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _changeProfilePicture,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getRoleDisplayName(user?.role ?? 'student'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_userStats != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('Préstamos', _userStats!['total_loans'].toString()),
                                _buildStatItem('Activos', _userStats!['active_loans'].toString()),
                                _buildStatItem('Completados', _userStats!['completed_loans'].toString()),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Información personal
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre Completo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo Electrónico',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su correo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            
                            if (user?.program != null) ...[
                              TextFormField(
                                initialValue: user!.program,
                                decoration: const InputDecoration(
                                  labelText: 'Programa de Formación',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.school),
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            if (user?.ficha != null) ...[
                              TextFormField(
                                initialValue: user!.ficha,
                                decoration: const InputDecoration(
                                  labelText: 'Ficha',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                readOnly: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer<UserSettingsService>(
                    builder: (context, settingsService, child) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Configuraciones',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tema
                              SwitchListTile(
                                title: const Text('Modo Oscuro'),
                                subtitle: const Text('Cambiar apariencia de la aplicación'),
                                value: settingsService.isDarkMode,
                                onChanged: settingsService.isLoading ? null : (value) async {
                                  try {
                                    await settingsService.toggleDarkMode();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al cambiar tema: $e')),
                                    );
                                  }
                                },
                                secondary: Icon(
                                  settingsService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                  color: AppColors.primary,
                                ),
                              ),
                              
                              // Notificaciones
                              SwitchListTile(
                                title: const Text('Notificaciones'),
                                subtitle: const Text('Recibir notificaciones de la app'),
                                value: settingsService.notificationsEnabled,
                                onChanged: settingsService.isLoading ? null : (value) async {
                                  try {
                                    await settingsService.updateNotificationSettings(
                                      notificationsEnabled: value,
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al actualizar notificaciones: $e')),
                                    );
                                  }
                                },
                                secondary: const Icon(
                                  Icons.notifications,
                                  color: AppColors.primary,
                                ),
                              ),
                              
                              if (settingsService.notificationsEnabled) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    children: [
                                      SwitchListTile(
                                        title: const Text('Notificaciones por Email'),
                                        value: settingsService.emailNotifications,
                                        onChanged: settingsService.isLoading ? null : (value) async {
                                          try {
                                            await settingsService.updateNotificationSettings(
                                              emailNotifications: value,
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                      ),
                                      SwitchListTile(
                                        title: const Text('Notificaciones Push'),
                                        value: settingsService.pushNotifications,
                                        onChanged: settingsService.isLoading ? null : (value) async {
                                          try {
                                            await settingsService.updateNotificationSettings(
                                              pushNotifications: value,
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Language selection
                              ListTile(
                                leading: const Icon(Icons.language, color: AppColors.primary),
                                title: const Text('Idioma'),
                                subtitle: Text(settingsService.language == 'es' ? 'Español' : 'English'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: settingsService.isLoading ? null : () => _showLanguageDialog(settingsService),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Acciones
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ListTile(
                            leading: const Icon(Icons.lock, color: AppColors.primary),
                            title: const Text('Cambiar Contraseña'),
                            subtitle: const Text('Actualizar tu contraseña de acceso'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _changePassword,
                          ),
                          
                          ListTile(
                            leading: const Icon(Icons.history, color: AppColors.secondary),
                            title: const Text('Historial de Préstamos'),
                            subtitle: const Text('Ver tu historial completo'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _viewHistory,
                          ),
                          
                          ListTile(
                            leading: const Icon(Icons.help, color: AppColors.info),
                            title: const Text('Ayuda y Soporte'),
                            subtitle: const Text('Obtener ayuda o reportar problemas'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showHelp,
                          ),
                          
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.error),
                            title: const Text('Cerrar Sesión'),
                            subtitle: const Text('Salir de la aplicación'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón guardar cambios
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'student':
        return 'Aprendiz SENA';
      case 'instructor':
        return 'Instructor SENA';
      case 'supervisor':
        return 'Supervisor SENA';
      case 'admin':
        return 'Administrador';
      case 'admin_general':
        return 'Administrador General';
      default:
        return 'Usuario SENA';
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(UserSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: settingsService.language,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await settingsService.updateLanguage(value);
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cambiar idioma: $e')),
                    );
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: settingsService.language,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await settingsService.updateLanguage(value);
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cambiar idioma: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de Galería'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Eliminar Foto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement photo removal
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text('Funcionalidad para cambiar contraseña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _viewHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando al historial de préstamos...'),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda y Soporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para obtener ayuda:'),
            SizedBox(height: 8),
            Text('• Email: soporte@sena.edu.co'),
            Text('• Teléfono: +57 1 234 5678'),
            Text('• Horario: Lunes a Viernes 8:00 - 17:00'),
          ],
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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              // Clear settings cache on logout
              await UserSettingsService.instance.clearCache();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement profile update API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }
}
