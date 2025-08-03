import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GolfDetectionApp());
}

/// Application principale de détection de golf
class GolfDetectionApp extends StatelessWidget {
  const GolfDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Distance Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Couleurs principales
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        
        // Configuration de la barre d'état
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        
        // Couleurs de fond
        scaffoldBackgroundColor: Colors.grey.shade50,
        
        // Configuration des cartes
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
        ),
        
        // Configuration des boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        
        // Configuration des floating action buttons
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        
        // Configuration des onglets
        tabBarTheme: const TabBarTheme(
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        // Configuration des dividers
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
        
        // Configuration des snackbars
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
        
        // Utiliser Material Design 3
        useMaterial3: true,
      ),
      
      // Gestion de l'orientation
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Empêche la mise à l'échelle du texte
          ),
          child: child!,
        );
      },
      
      // Écran d'accueil
      home: const HomeScreen(),
    );
  }
}