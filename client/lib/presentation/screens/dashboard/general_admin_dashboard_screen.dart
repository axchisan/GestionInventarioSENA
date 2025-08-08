import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';

class GeneralAdminDashboardScreen extends StatelessWidget {
  const GeneralAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Administrador General',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida con logo SENA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(33),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(33),
                        child: Image.asset(
                          '/sena-logo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel Administrador General',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Control absoluto del sistema, seguridad, integraciones, monitoreo y configuración global.',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Métricas clave del sistema
            const Text(
              'Métricas Globales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat('Usuarios Totales', '1,560', Icons.people, AppColors.primary),
                _stat('Equipos Totales', '12,430', Icons.inventory_2, AppColors.secondary),
                _stat('Ambientes', '128', Icons.house, AppColors.accent),
                _stat('Préstamos Activos', '302', Icons.assignment, AppColors.warning),
                _stat('Sesiones Activas', '214', Icons.cloud, AppColors.info),
                _stat('Errores 24h', '7', Icons.error_outline, AppColors.error),
              ],
            ),
            const SizedBox(height: 24),

            // Acciones rápidas y navegación
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _action(context,
                    title: 'Control del Sistema',
                    subtitle: 'Backups, performance, flags',
                    icon: Icons.tune,
                    color: AppColors.primary,
                    route: '/system-control'),
                _action(context,
                    title: 'Gestión de Usuarios',
                    subtitle: 'Roles y aprobaciones',
                    icon: Icons.manage_accounts,
                    color: AppColors.secondary,
                    route: '/user-management'),
                _action(context,
                    title: 'Ambientes',
                    subtitle: 'Vista global de ambientes',
                    icon: Icons.home_work,
                    color: AppColors.accent,
                    route: '/environment-overview'),
                _action(context,
                    title: 'Estadísticas',
                    subtitle: 'Métricas avanzadas',
                    icon: Icons.query_stats,
                    color: AppColors.info,
                    route: '/statistics-dashboard'),
                _action(context,
                    title: 'Alertas',
                    subtitle: 'Alertas críticas del sistema',
                    icon: Icons.warning_amber,
                    color: AppColors.warning,
                    route: '/inventory-alerts'),
                _action(context,
                    title: 'Auditoría',
                    subtitle: 'Registro detallado',
                    icon: Icons.fact_check,
                    color: AppColors.error,
                    route: '/audit-log'),
                _action(context,
                    title: 'Reportes',
                    subtitle: 'PDF / Excel',
                    icon: Icons.description,
                    color: Colors.teal,
                    route: '/report-generator'),
                _action(context,
                    title: 'Centro de Seguridad',
                    subtitle: 'Políticas, sesiones, API keys',
                    icon: Icons.security,
                    color: Colors.deepPurple,
                    route: '/security-center'),
                _action(context,
                    title: 'Integraciones',
                    subtitle: 'Webhooks y terceros',
                    icon: Icons.extension,
                    color: Colors.indigo,
                    route: '/integrations'),
                _action(context,
                    title: 'Monitoreo',
                    subtitle: 'Salud y logs',
                    icon: Icons.monitor_heart,
                    color: Colors.brown,
                    route: '/monitoring'),
                _action(context,
                    title: 'Configuración',
                    subtitle: 'Tema, idioma y más',
                    icon: Icons.settings,
                    color: AppColors.grey600,
                    route: '/settings'),
                _action(context,
                    title: 'Feedback',
                    subtitle: 'Sugerencias internas',
                    icon: Icons.feedback,
                    color: Colors.orange,
                    route: '/feedback-form'),
              ],
            ),
            const SizedBox(height: 24),

            // Actividad reciente
            const Text(
              'Actividad Reciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _ActivityTile(
                    icon: Icons.check_circle,
                    title: 'Backup completado',
                    subtitle: 'Backup incremental realizado con éxito',
                    time: 'hace 12 min',
                    color: AppColors.success,
                  ),
                  _ActivityTile(
                    icon: Icons.warning_amber,
                    title: 'Alerta de almacenamiento',
                    subtitle: 'Uso de disco al 92% en nodo DB-02',
                    time: 'hace 27 min',
                    color: AppColors.warning,
                  ),
                  _ActivityTile(
                    icon: Icons.security,
                    title: 'Política de contraseñas actualizada',
                    subtitle: 'Requerido mínimo 12 caracteres',
                    time: 'hace 1 h',
                    color: AppColors.info,
                  ),
                  _ActivityTile(
                    icon: Icons.extension,
                    title: 'Webhook de reportes activado',
                    subtitle: 'Integración con Google Drive',
                    time: 'hace 2 h',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      drawer: _drawer(context),
    );
  }

  static Widget _stat(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _action(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: color),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.grey600)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo SENA
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Image(
                        image: AssetImage('/sena-logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Administrador General',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('superadmin@sena.edu.co', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Dashboard'),
            onTap: () => context.go('/general-admin-dashboard-screen'),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Control del Sistema'),
            onTap: () => context.push('/system-control'),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Gestión de Usuarios'),
            onTap: () => context.push('/user-management'),
          ),
          ListTile(
            leading: const Icon(Icons.home_work),
            title: const Text('Ambientes'),
            onTap: () => context.push('/environment-overview'),
          ),
          ListTile(
            leading: const Icon(Icons.query_stats),
            title: const Text('Estadísticas'),
            onTap: () => context.push('/statistics-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Alertas'),
            onTap: () => context.push('/inventory-alerts'),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check),
            title: const Text('Auditoría'),
            onTap: () => context.push('/audit-log'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Reportes'),
            onTap: () => context.push('/report-generator'),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Centro de Seguridad'),
            onTap: () => context.push('/security-center'),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Integraciones'),
            onTap: () => context.push('/integrations'),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Monitoreo'),
            onTap: () => context.push('/monitoring'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () => context.push('/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
    );
  }
}
