import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 Import necesario
import 'screens/dashboard.dart'; // Importamos el dashboard
import 'screens/login.dart'; // Importamos el login
import 'services/auth_service.dart'; // Importamos el servicio de auth

// 🔹 Observador de rutas
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la franja de "debug"
      title: 'Inventario',
      navigatorObservers: [routeObserver], // ✅ Observador de rutas
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),

      // 🌍 Configuración de idioma en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España (funciona igual para Latinoamérica)
      ],
      locale: const Locale('es', 'ES'),

      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          // Mientras carga SharedPreferences
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
            );
          }
          // Si tiene token, va al Dashboard; si no, al Login
          if (snapshot.hasData && snapshot.data == true) {
            return const DashboardPage();
          } else {
            return const LoginPage();
          }
        },
      ), // Pantalla inicial protegida
    );
  }
}
