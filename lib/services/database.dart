import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static var db, userCollection, productCollection;
  static bool isConnected = false;

  /// Retourne l'URL de connexion MongoDB correcte selon la plateforme
  /// - Android émulateur : 10.0.2.2 pointe vers la machine hôte (ton Mac)
  /// - Autres plateformes (iOS, macOS, etc.) : localhost
  static String _getConnectionString() {
    if (Platform.isAndroid) {
      // IMPORTANT : sur l'émulateur Android, "localhost" pointe vers l'émulateur lui‑même,
      // pas vers ton Mac. 10.0.2.2 est l'adresse spéciale pour accéder au host.
      return "mongodb://10.0.2.2:27017/flutter";
    }

    // iOS Simulator / macOS / autres
    return "mongodb://localhost:27017/flutter";
  }

  static connect() async {
    try {
      String connectionString = _getConnectionString();
      
      print("🔄 Tentative de connexion à MongoDB: $connectionString");
      db = await Db.create(connectionString);
      await db.open().timeout(
        const Duration(seconds: 5), // Réduit à 5 secondes pour un retour plus rapide
        onTimeout: () {
          throw Exception('Timeout de connexion à MongoDB. Vérifiez que MongoDB est démarré.');
        },
      );
      userCollection = db.collection('users');
      productCollection = db.collection('products');
      isConnected = true;
      print("✓ Connexion MongoDB réussie!");
      print("✓ Base de données: flutter");
      print("✓ Collection: users");
      print("✓ Collection: products");
      
      try {
        int count = await userCollection.count();
        print("✓ Nombre d'utilisateurs dans la collection: $count");
      } catch (e) {
        print("⚠️ Impossible de compter les documents: $e");
      }
    } catch (e) {
      isConnected = false;
      userCollection = null;
      print("✗ Erreur de connexion MongoDB: $e");
      print("\n💡 La cause la plus probable est que le service MongoDB n'est pas démarré.");
      print("   Solution: Ouvrez un terminal et exécutez 'brew services start mongodb-community'");
      rethrow;
    }
  }

  /// Tente de se reconnecter à MongoDB
  static Future<bool> reconnect() async {
    try {
      await connect();
      await createDefaultUsers();
      await syncProductsFromFakeStore();
      return true;
    } catch (e) {
      print("✗ Échec de la reconnexion: $e");
      return false;
    }
  }

  /// Crée les 3 utilisateurs par défaut (admin, client, vendeur)
  static Future<void> createDefaultUsers() async {
    if (userCollection == null) {
      print("⚠️ Impossible de créer les utilisateurs: MongoDB non connecté");
      return;
    }
    
    // Créer l'utilisateur Admin
    var admin = await MongoDatabase.userCollection.findOne({'email': 'admin@admin.com'});
    if (admin == null) {
      await MongoDatabase.userCollection.insert({
        'email': 'admin@admin.com',
        'password': 'admin123', // You should hash this password
        'role': 'admin',
        'username': 'admin',
        'firstName': 'Admin',
        'lastName': 'User',
      });
      print("✓ Admin account created: admin@admin.com / admin123");
    }

    // Créer l'utilisateur Client
    var client = await MongoDatabase.userCollection.findOne({'email': 'client@client.com'});
    if (client == null) {
      await MongoDatabase.userCollection.insert({
        'email': 'client@client.com',
        'password': 'client123', // You should hash this password
        'role': 'client',
        'username': 'client',
        'firstName': 'Client',
        'lastName': 'User',
      });
      print("✓ Client account created: client@client.com / client123");
    }

    // Créer l'utilisateur Vendeur
    var vendeur = await MongoDatabase.userCollection.findOne({'email': 'vendeur@vendeur.com'});
    if (vendeur == null) {
      await MongoDatabase.userCollection.insert({
        'email': 'vendeur@vendeur.com',
        'password': 'vendeur123', // You should hash this password
        'role': 'vendeur',
        'username': 'vendeur',
        'firstName': 'Vendeur',
        'lastName': 'User',
      });
      print("✓ Vendeur account created: vendeur@vendeur.com / vendeur123");
    }
  }

  /// Récupère les produits depuis FakeStoreAPI et les stocke dans la collection `products`
  /// - Ne réimporte pas si la collection contient déjà des documents
  static Future<void> syncProductsFromFakeStore() async {
    if (db == null || productCollection == null) {
      print("⚠️ Impossible de synchroniser les produits: MongoDB non connecté");
      return;
    }

    try {
      final existingCount = await productCollection.count();
      if (existingCount > 0) {
        print("ℹ️ Collection 'products' déjà remplie ($existingCount documents), pas de réimport.");
        return;
      }

      print("🔄 Récupération des produits depuis FakeStoreAPI...");
      final response = await http
          .get(Uri.parse('https://fakestoreapi.com/products'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print("✗ Erreur FakeStoreAPI: code HTTP ${response.statusCode}");
        return;
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      final products = data.map((dynamic item) {
        final Map<String, dynamic> p = item as Map<String, dynamic>;
        final rating = p['rating'] as Map<String, dynamic>? ?? {};

        return {
          'apiId': p['id'],
          'title': p['title'],
          'price': (p['price'] as num).toDouble(),
          'description': p['description'],
          'category': p['category'],
          'image': p['image'],
          'rating': {
            'rate': rating['rate'] != null ? (rating['rate'] as num).toDouble() : null,
            'count': rating['count'],
          },
        };
      }).toList();

      if (products.isEmpty) {
        print("ℹ️ Aucun produit reçu depuis FakeStoreAPI.");
        return;
      }

      await productCollection.insertMany(products);
      print("✓ ${products.length} produits insérés dans la collection 'products'.");
    } on SocketException {
      print("✗ Impossible d'atteindre FakeStoreAPI (problème réseau).");
    } on TimeoutException {
      print("✗ Timeout en appelant FakeStoreAPI.");
    } catch (e) {
      print("✗ Erreur lors de la synchronisation des produits: $e");
    }
  }
}
