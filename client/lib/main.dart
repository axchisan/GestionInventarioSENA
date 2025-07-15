import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/services/theme_service.dart';
import 'core/services/language_service.dart';
import 'core/services/navigation_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await ThemeService.instance.init();
  await LanguageService.instance.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService.instance),
        ChangeNotifierProvider(create: (_) => LanguageService.instance),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Desactivamos temporalmente providers no usados hasta que se implementen
        // ChangeNotifierProvider(create: (_) => InventoryProvider()),
        // ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const SenaInventoryApp(),
    ),
  );
}

class SenaInventoryApp extends StatelessWidget {
  const SenaInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp.router(
          title: 'SENA Inventory',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeService.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'CO')],
          routerConfig: NavigationService.router,
        );
      },
    );
  }
}