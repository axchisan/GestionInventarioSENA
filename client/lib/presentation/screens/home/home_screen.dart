import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/sena_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SenaAppBar(
        title: 'Dashboard Principal',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Items',
                    '1,234',
                    Icons.inventory,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Préstamos',
                    '45',
                    Icons.assignment,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Alertas',
                    '12',
                    Icons.warning,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Mantenimiento',
                    '8',
                    Icons.build,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Escanear QR',
                  Icons.qr_code_scanner,
                  AppColors.primary,
                  '/qr-scan',
                ),
                _buildActionCard(
                  context,
                  'Verificar Inventario',
                  Icons.checklist,
                  AppColors.secondary,
                  '/inventory-check',
                ),
                _buildActionCard(
                  context,
                  'Solicitar Préstamo',
                  Icons.assignment_add,
                  AppColors.accent,
                  '/loan-request',
                ),
                _buildActionCard(
                  context,
                  'Mantenimiento',
                  Icons.build_circle,
                  AppColors.warning,
                  '/maintenance-request',
                ),
                _buildActionCard(
                  context,
                  'Estadísticas',
                  Icons.analytics,
                  AppColors.info,
                  '/statistics',
                ),
                _buildActionCard(
                  context,
                  'Notificaciones',
                  Icons.notifications,
                  AppColors.error,
                  '/notifications',
                ),
              ],
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
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
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
              color: AppColors.primary,
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
                  'Usuario Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'usuario@sena.edu.co',
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
            onTap: () => context.go('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Panel Admin'),
            onTap: () => context.push('/admin-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.supervisor_account),
            title: const Text('Panel Supervisor'),
            onTap: () => context.push('/supervisor-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () => context.push('/profile'),
          ),
          const Divider(),
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
