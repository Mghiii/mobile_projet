import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';
import 'package:miniprojet/views/AdminDashboard.dart';
import 'package:miniprojet/views/ClientDashboard.dart';
import 'package:miniprojet/views/LoginScreen.dart';
import 'package:miniprojet/views/SingUpScreen.dart';
import 'package:miniprojet/views/VendeurDashboard.dart';
import 'package:miniprojet/views/ShoppingCartScreen.dart';
import 'package:miniprojet/views/ProfileScreen.dart';
import 'package:miniprojet/views/SettingsScreen.dart';
import 'package:miniprojet/views/CategoriesScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tenter de se connecter à MongoDB (ne bloque pas l'application si échec)
  try {
    await MongoDatabase.connect();
    await MongoDatabase.createDefaultUsers(); // Crée les 3 utilisateurs (admin, client, vendeur)
    await MongoDatabase.syncProductsFromFakeStore(); // Importe les produits FakeStoreAPI dans la collection products
    print("✓ Application prête avec MongoDB connecté");
  } catch (e) {
    MongoDatabase.isConnected = false;
    print("⚠️ Erreur de connexion MongoDB: $e");
    print("⚠️ L'application démarre quand même, mais les fonctionnalités de base de données ne seront pas disponibles.");
    print("⚠️ Vous pouvez insérer les utilisateurs manuellement via MongoDB Compass (voir GUIDE_MONGODB.md)");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        //backgroundColor: Colors.black,
        cardColor: Colors.grey.shade900,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
          surface: Colors.grey.shade900,
          background: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Loginscreen(),
        '/login': (context) => const Loginscreen(),
        '/signup': (context) => const Singupscreen(),
        '/admin': (context) => const AdminDashboard(),
        '/client': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return ClientDashboard(initialCategory: args as String?);
        },
        '/vendeur': (context) => const VendeurDashboard(),
        '/cart': (context) => const ShoppingCartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/categories': (context) => const CategoriesScreen(),
      },
    );
  }
}
