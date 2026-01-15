import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';
import 'package:miniprojet/views/ClientDashboard.dart';
import 'package:miniprojet/views/LoginScreen.dart';
import 'package:miniprojet/views/ShoppingCartScreen.dart';
import 'package:miniprojet/views/SingUpScreen.dart';
import 'package:miniprojet/views/VendeurDashboard.dart';
import 'package:miniprojet/views/admin_dashboard.dart';
import 'package:miniprojet/views/client_dashboard.dart';
import 'package:miniprojet/views/VendeurAddProductScreen.dart';
import 'package:miniprojet/views/VendeurEditProductScreen.dart';
import 'package:miniprojet/views/VendeurProfileScreen.dart';
import 'package:miniprojet/views/VendeurSettingsScreen.dart';
//import 'package:miniprojet/views/login_screen.dart';
//import 'package:miniprojet/views/shopping_cart_screen.dart';
//import 'package:miniprojet/views/signup_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await MongoDatabase.connect();
    await MongoDatabase.createDefaultUsers();
    await MongoDatabase.syncProductsFromFakeStore();
    if (kDebugMode) {
      print("✓ Application prête avec MongoDB connecté");
    }
  } catch (e) {
    MongoDatabase.isConnected = false;
    if (kDebugMode) {
      print("⚠️ Erreur de connexion MongoDB: $e");
      print(
          "⚠️ L'application démarre quand même, mais les fonctionnalités de base de données ne seront pas disponibles.");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Loginscreen(),
        '/login': (context) => const Loginscreen(),
        '/signup': (context) => const Singupscreen(),
        '/admin': (context) => const AdminDashboard(),
        '/client': (context) => const ClientDashboard(),
        '/cart': (context) => const ShoppingCartScreen(),
        // Routes de l'espace vendeur
        '/vendeur': (context) => const VendeurDashboard(),
        '/vendeur-add-product': (context) => const VendeurAddProductScreen(),
        '/vendeur-edit-product': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return VendeurEditProductScreen(product: args);
          }
          throw Exception('Produit requis pour la modification');
        },
        '/vendeur-profile': (context) => const VendeurProfileScreen(),
        '/vendeur-settings': (context) => const VendeurSettingsScreen(),
      },
    );
  }
}
