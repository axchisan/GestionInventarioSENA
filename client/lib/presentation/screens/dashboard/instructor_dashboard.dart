import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/sena_app_bar.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Panel de Instructor',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/sena_logo.png',
                          width: 50,
                          height: 50,
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
                            '¡Bienvenido, Instructor!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestiona el inventario de tu ambiente y supervisa préstamos',
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
            const SizedBox(height: 24),

            const Text(
              'Mi Ambiente de Formación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Equipos Totales',
                    '45',
                    Icons.inventory,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'En Préstamo',
                    '12',
                    Icons.assignment,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Disponibles',
                    '33',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Mantenimiento',
                    '2',
                    Icons.build,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Gestión de Ambiente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  context,
                  'Verificar Inventario',
                  'Actualiza estado de equipos',
                  Icons.checklist,
                  AppColors.secondary,
                  '/inventory-check',
                ),
                _buildActionCard(
                  context,
                  'Escanear QR',
                  'Identifica equipos rápidamente',
                  Icons.qr_code_scanner,
                  AppColors.primary,
                  '/qr-generate',
                ),
                _buildActionCard(
                  context,
                  'Préstamos Activos',
                  'Gestiona préstamos del ambiente',
                  Icons.assignment,
                  AppColors.accent,
                  '/loan-history',
                ),
                _buildActionCard(
                  context,
                  'Solicitar Mantenimiento',
                  'Reporta equipos dañados',
                  Icons.build_circle,
                  AppColors.warning,
                  '/maintenance-request',
                ),
                _buildActionCard(
                  context,
                  'Historial de Inventario',
                  'Consulta movimientos',
                  Icons.history,
                  AppColors.info,
                  '/inventory-history',
                ),
                _buildActionCard(
                  context,
                  'Ambiente Overview',
                  'Vista general del ambiente',
                  Icons.location_on,
                  AppColors.success,
                  '/environment-overview',
                ),
                _buildActionCard(
                  context,
                  'Cronograma',
                  'Horarios de capacitación',
                  Icons.schedule,
                  AppColors.primary,
                  '/training-schedule',
                ),
                _buildActionCard(
                  context,
                  'Notificaciones',
                  'Alertas y mensajes',
                  Icons.notifications,
                  AppColors.error,
                  '/notifications',
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alertas Recientes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAlertItem('Equipo requiere mantenimiento', 'Taladro Industrial #001', AppColors.warning),
                    _buildAlertItem('Préstamo próximo a vencer', 'Laptop Dell - Juan Pérez', AppColors.error),
                    _buildAlertItem('Nuevo equipo agregado', 'Proyector Epson #045', AppColors.success),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/inventory-alerts'),
                      child: const Text('Ver todas las alertas'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.secondary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/sena_logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Panel de Instructor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'instructor@sena.edu.co',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/instructor-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Verificar Inventario'),
            onTap: () => context.push('/inventory-check'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Préstamos'),
            onTap: () => context.push('/loan-history'),
          ),
          ListTile(
            leading: const Icon(Icons.build_circle),
            title: const Text('Mantenimiento'),
            onTap: () => context.push('/maintenance-request'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Mi Ambiente'),
            onTap: () => context.push('/environment-overview'),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Cronograma'),
            onTap: () => context.push('/training-schedule'),
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
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}