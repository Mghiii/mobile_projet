import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static var db, userCollection, productCollection;
  static bool isConnected = false;
  static Map<String, dynamic>? currentUser; // Utilisateur connecté actuellement

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

  /// Récupère tous les vendeurs de la collection users
  static Future<List<Map<String, dynamic>>> _getVendeurs() async {
    if (userCollection == null) {
      return [];
    }
    try {
      final vendeurs = await userCollection.find({'role': 'vendeur'}).toList();
      return vendeurs.cast<Map<String, dynamic>>();
    } catch (e) {
      print("⚠️ Erreur lors de la récupération des vendeurs: $e");
      return [];
    }
  }

  /// Récupère les produits depuis DummyJSON, puis les stocke dans la collection `products`
  /// - Assigne chaque produit à un vendeur de manière équitable
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
        // Redistribuer les produits existants aux vendeurs s'ils n'ont pas de vendeurId
        await _assignProductsToVendeurs();
        return;
      }

      // Récupérer tous les vendeurs une seule fois
      final vendeurs = await _getVendeurs();
      if (vendeurs.isEmpty) {
        print("⚠️ Aucun vendeur trouvé. Les produits seront créés sans vendeur assigné.");
      }

      final allProducts = <Map<String, dynamic>>[];
      int productIndex = 0;

      // Récupérer TOUS les produits depuis DummyJSON avec pagination automatique
      try {
        print("🔄 Récupération de TOUS les produits depuis DummyJSON...");
        
        // DummyJSON supporte la pagination avec limit et skip
        const int limitPerPage = 100; // Maximum par page selon la doc
        
        // D'abord, récupérer la première page pour connaître le total disponible
        print("  📄 Récupération de la première page pour connaître le total...");
        final firstPageResponse = await http
            .get(Uri.parse('https://dummyjson.com/products?limit=$limitPerPage&skip=0'))
            .timeout(const Duration(seconds: 15));

        if (firstPageResponse.statusCode != 200) {
          print("  ⚠️ Erreur DummyJSON première page: code HTTP ${firstPageResponse.statusCode}");
          throw Exception('Erreur lors de la récupération de la première page');
        }

        final Map<String, dynamic> firstPageData = jsonDecode(firstPageResponse.body) as Map<String, dynamic>;
        final int totalAvailable = firstPageData['total'] as int? ?? 0;
        final List<dynamic> firstPageProducts = firstPageData['products'] as List<dynamic>? ?? [];
        
        print("  ℹ️ Total de produits disponibles sur DummyJSON: $totalAvailable");
        
        if (totalAvailable == 0) {
          print("  ⚠️ Aucun produit disponible sur DummyJSON.");
        } else {
          // Calculer le nombre de pages nécessaires
          final int numberOfPages = (totalAvailable / limitPerPage).ceil();
          print("  📊 Nombre de pages à récupérer: $numberOfPages");
          
          int totalDummyProducts = 0;
          
          // Traiter la première page déjà récupérée
          for (final item in firstPageProducts) {
            final Map<String, dynamic> p = item as Map<String, dynamic>;
            final rating = p['rating'] as num?;
            final discountPercentage = p['discountPercentage'] as num?;
            final stock = p['stock'] as num?;
            final brand = p['brand'] as String?;
            final images = p['images'] as List<dynamic>?;

            // Assigner le produit à un vendeur de manière circulaire
            String? vendeurId;
            String? vendeurEmail;
            String? vendeurName;
            if (vendeurs.isNotEmpty) {
              final vendeur = vendeurs[productIndex % vendeurs.length];
              vendeurId = vendeur['_id']?.toString();
              vendeurEmail = vendeur['email']?.toString();
              vendeurName = '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim();
              if (vendeurName.isEmpty) {
                vendeurName = vendeur['username']?.toString();
              }
            }

            // Utiliser la première image si disponible, sinon l'image principale
            String? imageUrl = p['thumbnail'] as String?;
            if (images != null && images.isNotEmpty) {
              imageUrl = images[0] as String? ?? imageUrl;
            }

            // S'assurer que tous les produits ont une promotion
            // Si le produit n'a pas de promotion, en ajouter une aléatoire entre 5% et 30%
            double finalDiscountPercentage;
            if (discountPercentage != null) {
              finalDiscountPercentage = discountPercentage.toDouble();
            } else {
              final random = (productIndex * 11 + 17) % 26; // Pseudo-aléatoire basé sur l'index
              finalDiscountPercentage = (5.0 + random).roundToDouble();
            }

            allProducts.add({
              'apiId': p['id'],
              'apiSource': 'DummyJSON',
              'title': p['title'],
              'price': (p['price'] as num).toDouble(),
              'description': p['description'] ?? '',
              'category': p['category'] ?? '',
              'image': imageUrl,
              'brand': brand,
              'stock': stock?.toInt(),
              'discountPercentage': finalDiscountPercentage,
              'vendeurId': vendeurId,
              'vendeurEmail': vendeurEmail,
              'vendeurName': vendeurName,
              'rating': {
                'rate': rating?.toDouble(),
                'count': null, // DummyJSON ne fournit pas le count
              },
            });
            productIndex++;
          }
          
          totalDummyProducts += firstPageProducts.length;
          print("  ✓ ${firstPageProducts.length} produits récupérés de la page 1/$numberOfPages.");
          
          // Récupérer les pages suivantes si nécessaire
          for (int page = 1; page < numberOfPages; page++) {
            final skip = page * limitPerPage;
            final url = 'https://dummyjson.com/products?limit=$limitPerPage&skip=$skip';
            
            try {
              print("  📄 Page ${page + 1}/$numberOfPages (skip: $skip)...");
              final dummyJsonResponse = await http
                  .get(Uri.parse(url))
                  .timeout(const Duration(seconds: 15));

              if (dummyJsonResponse.statusCode == 200) {
                final Map<String, dynamic> dummyJsonData = jsonDecode(dummyJsonResponse.body) as Map<String, dynamic>;
                final List<dynamic> dummyProducts = dummyJsonData['products'] as List<dynamic>? ?? [];
                
                // Si on n'a plus de produits, arrêter la pagination
                if (dummyProducts.isEmpty) {
                  print("  ℹ️ Plus de produits disponibles, arrêt de la pagination.");
                  break;
                }
                
                for (final item in dummyProducts) {
                  final Map<String, dynamic> p = item as Map<String, dynamic>;
                  final rating = p['rating'] as num?;
                  final discountPercentage = p['discountPercentage'] as num?;
                  final stock = p['stock'] as num?;
                  final brand = p['brand'] as String?;
                  final images = p['images'] as List<dynamic>?;

                  // Assigner le produit à un vendeur de manière circulaire
                  String? vendeurId;
                  String? vendeurEmail;
                  String? vendeurName;
                  if (vendeurs.isNotEmpty) {
                    final vendeur = vendeurs[productIndex % vendeurs.length];
                    vendeurId = vendeur['_id']?.toString();
                    vendeurEmail = vendeur['email']?.toString();
                    vendeurName = '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim();
                    if (vendeurName.isEmpty) {
                      vendeurName = vendeur['username']?.toString();
                    }
                  }

                  // Utiliser la première image si disponible, sinon l'image principale
                  String? imageUrl = p['thumbnail'] as String?;
                  if (images != null && images.isNotEmpty) {
                    imageUrl = images[0] as String? ?? imageUrl;
                  }

                  // S'assurer que tous les produits ont une promotion
                  // Si le produit n'a pas de promotion, en ajouter une aléatoire entre 5% et 30%
                  double finalDiscountPercentage;
                  if (discountPercentage != null) {
                    finalDiscountPercentage = discountPercentage.toDouble();
                  } else {
                    final random = (productIndex * 11 + 17) % 26; // Pseudo-aléatoire basé sur l'index
                    finalDiscountPercentage = (5.0 + random).roundToDouble();
                  }

                  allProducts.add({
                    'apiId': p['id'],
                    'apiSource': 'DummyJSON',
                    'title': p['title'],
                    'price': (p['price'] as num).toDouble(),
                    'description': p['description'] ?? '',
                    'category': p['category'] ?? '',
                    'image': imageUrl,
                    'brand': brand,
                    'stock': stock?.toInt(),
                    'discountPercentage': finalDiscountPercentage,
                    'vendeurId': vendeurId,
                    'vendeurEmail': vendeurEmail,
                    'vendeurName': vendeurName,
                    'rating': {
                      'rate': rating?.toDouble(),
                      'count': null, // DummyJSON ne fournit pas le count
                    },
                  });
                  productIndex++;
                }
                
                totalDummyProducts += dummyProducts.length;
                print("  ✓ ${dummyProducts.length} produits récupérés de la page ${page + 1}/$numberOfPages.");
                
                // Petite pause entre les requêtes pour éviter de surcharger l'API
                await Future.delayed(const Duration(milliseconds: 200));
              } else {
                print("  ⚠️ Erreur DummyJSON page ${page + 1}: code HTTP ${dummyJsonResponse.statusCode}");
                break; // Arrêter si erreur HTTP
              }
            } on TimeoutException {
              print("  ⚠️ Timeout sur la page ${page + 1} de DummyJSON.");
              break; // Arrêter si timeout
            } catch (e) {
              print("  ⚠️ Erreur sur la page ${page + 1} de DummyJSON: $e");
              break; // Arrêter en cas d'erreur
            }
          }
          
          print("✓ $totalDummyProducts produits récupérés depuis DummyJSON (sur $totalAvailable disponibles).");
        }
      } on SocketException {
        print("⚠️ Impossible d'atteindre DummyJSON (problème réseau).");
      } catch (e) {
        print("⚠️ Erreur lors de la récupération depuis DummyJSON: $e");
      }

      if (allProducts.isEmpty) {
        print("ℹ️ Aucun produit récupéré depuis DummyJSON.");
        return;
      }

      await productCollection.insertMany(allProducts);
      print("\n" + "="*60);
      print("✓ SYNCHRONISATION RÉUSSIE - Dataset créé !");
      print("="*60);
      print("📊 Total produits récupérés: ${allProducts.length}");
      print("   └─ DummyJSON: ${allProducts.length} produits");
      print("✓ ${allProducts.length} produits insérés dans la collection 'products'.");
      if (vendeurs.isNotEmpty) {
        print("✓ Produits assignés équitablement à ${vendeurs.length} vendeur(s).");
      }
      print("="*60 + "\n");
    } catch (e) {
      print("✗ Erreur lors de la synchronisation des produits: $e");
    }
  }

  /// Assigne les produits existants aux vendeurs s'ils n'ont pas encore de vendeurId
  static Future<void> _assignProductsToVendeurs() async {
    if (productCollection == null) {
      return;
    }

    try {
      final vendeurs = await _getVendeurs();
      if (vendeurs.isEmpty) {
        print("ℹ️ Aucun vendeur trouvé pour assigner les produits.");
        return;
      }

      // Récupérer tous les produits sans vendeurId
      final produitsSansVendeur = await productCollection
          .find({'vendeurId': null})
          .toList() as List<Map<String, dynamic>>;

      if (produitsSansVendeur.isEmpty) {
        print("ℹ️ Tous les produits ont déjà un vendeur assigné.");
        return;
      }

      print("🔄 Attribution de ${produitsSansVendeur.length} produits aux vendeurs...");

      for (int i = 0; i < produitsSansVendeur.length; i++) {
        final produit = produitsSansVendeur[i];
        final vendeur = vendeurs[i % vendeurs.length];
        
        await productCollection.update(
          {'_id': produit['_id']},
          {
            '\$set': {
              'vendeurId': vendeur['_id']?.toString(),
              'vendeurEmail': vendeur['email']?.toString(),
              'vendeurName': '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim().isEmpty
                  ? vendeur['username']?.toString()
                  : '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim(),
            }
          },
        );
      }

      print("✓ ${produitsSansVendeur.length} produits assignés aux vendeurs.");
    } catch (e) {
      print("✗ Erreur lors de l'assignation des produits aux vendeurs: $e");
    }
  }

  /// Récupère tous les produits d'un vendeur par son email
  static Future<List<Map<String, dynamic>>> getProductsByVendeurEmail(String vendeurEmail) async {
    if (productCollection == null) {
      return [];
    }

    try {
      final products = await productCollection
          .find({'vendeurEmail': vendeurEmail})
          .toList() as List<Map<String, dynamic>>;
      return products;
    } catch (e) {
      print("✗ Erreur lors de la récupération des produits du vendeur: $e");
      return [];
    }
  }

  /// Déconnecte l'utilisateur actuel
  static void logout() {
    currentUser = null;
  }
}
