import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/role_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.delayed(const Duration(milliseconds: 850));
      final authProvider = context.read<AuthProvider>();

      if (!mounted || _navigated) return;

      final hasSession = await authProvider.checkSession();

      if (!hasSession) {
        _navigateToLogin();
        return;
      }

      final role = authProvider.currentUser?.role;
      if (role != null) {
        _navigateByRole(role);
      } else {
        _navigateToLogin();
      }
    } catch (_) {
      if (!mounted || _navigated) return;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    _navigated = true;
    context.go('/login');
  }

  void _navigateByRole(String role) {
    _navigated = true;
    RoleNavigationService.navigateByRole(context, role);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const senaGreen = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F1512)
          : Colors.white,
      body: SafeArea(
        child: Semantics(
          label: 'Pantalla de inicio SENA, verificando sesión',
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/sena_logo.png', // Ajusta la ruta según tu estructura
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          semanticLabel: 'Logo del SENA',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SENA Inventory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0B1B13),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cargando y validando tu sesión...',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(strokeWidth: 3.0),
                      ),
                      const SizedBox(height: 32),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1B2A22)
                                  : const Color(0xFFEAF5EE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: senaGreen,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gestión de inventarios segura y ágil para todos los roles.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'v1.0.0',
                          semanticsLabel: 'Versión 1.0.0',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}