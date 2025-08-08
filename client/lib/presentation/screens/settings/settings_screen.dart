import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSync = true;
  bool _biometricAuth = false;
  String _language = 'Español';
  String _theme = 'Sistema';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(title: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección Apariencia
          _buildSectionHeader('Apariencia'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Modo Oscuro'),
                  subtitle: const Text('Cambiar entre tema claro y oscuro'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
                ListTile(
                  title: const Text('Idioma'),
                  subtitle: Text(_language),
                  leading: const Icon(Icons.language),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showLanguageDialog(),
                ),
                ListTile(
                  title: const Text('Tema'),
                  subtitle: Text(_theme),
                  leading: const Icon(Icons.palette),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showThemeDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección Notificaciones
          _buildSectionHeader('Notificaciones'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones Push'),
                  subtitle: const Text('Recibir notificaciones del sistema'),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                  secondary: const Icon(Icons.notifications),
                ),
                ListTile(
                  title: const Text('Configurar Notificaciones'),
                  subtitle: const Text('Personalizar tipos de notificaciones'),
                  leading: const Icon(Icons.tune),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showNotificationSettings(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección Sincronización
          _buildSectionHeader('Sincronización'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sincronización Automática'),
                  subtitle: const Text('Sincronizar datos automáticamente'),
                  value: _autoSync,
                  onChanged: (value) {
                    setState(() {
                      _autoSync = value;
                    });
                  },
                  secondary: const Icon(Icons.sync),
                ),
                ListTile(
                  title: const Text('Sincronizar Ahora'),
                  subtitle: const Text('Última sincronización: Hace 5 min'),
                  leading: const Icon(Icons.cloud_sync),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _syncNow(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección Seguridad
          _buildSectionHeader('Seguridad'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Autenticación Biométrica'),
                  subtitle: const Text('Usar huella dactilar o Face ID'),
                  value: _biometricAuth,
                  onChanged: (value) {
                    setState(() {
                      _biometricAuth = value;
                    });
                  },
                  secondary: const Icon(Icons.fingerprint),
                ),
                ListTile(
                  title: const Text('Cambiar PIN'),
                  subtitle: const Text('Actualizar código de seguridad'),
                  leading: const Icon(Icons.lock),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _changePIN(),
                ),
                ListTile(
                  title: const Text('Cerrar Sesión'),
                  subtitle: const Text('Salir de la aplicación'),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _logout(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección Información
          _buildSectionHeader('Información'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Acerca de'),
                  subtitle: const Text('Versión 1.0.0'),
                  leading: const Icon(Icons.info),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAbout(),
                ),
                ListTile(
                  title: const Text('Términos y Condiciones'),
                  leading: const Icon(Icons.description),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showTerms(),
                ),
                ListTile(
                  title: const Text('Política de Privacidad'),
                  leading: const Icon(Icons.privacy_tip),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPrivacy(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF00A651),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'Español',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Sistema'),
              value: 'Sistema',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Claro'),
              value: 'Claro',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Oscuro'),
              value: 'Oscuro',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    // Implementar configuración de notificaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de notificaciones')),
    );
  }

  void _syncNow() {
    // Implementar sincronización
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando datos...')),
    );
  }

  void _changePIN() {
    // Implementar cambio de PIN
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambiar PIN')),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'SENA Inventory',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/sena-logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      children: const [
        Text('Sistema de Gestión de Inventario SENA\n\nDesarrollado para optimizar el control y seguimiento de equipos e instrumentos en los ambientes de formación.'),
      ],
    );
  }

  void _showTerms() {
    // Implementar términos y condiciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Términos y Condiciones')),
    );
  }

  void _showPrivacy() {
    // Implementar política de privacidad
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Política de Privacidad')),
    );
  }
}
