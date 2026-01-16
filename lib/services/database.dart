import 'dart:async';
import 'dart:convert';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class MongoDatabase {
  // We keep the name "MongoDatabase" to avoid breaking the rest of your app,
  // but internally it is now using Firestore.
  static FirebaseFirestore? _db;
  static FirebaseFirestore get db {
    _db ??= FirebaseFirestore.instance;
    return _db!;
  }
  static Map<String, dynamic>? currentUser;
  static bool isConnected = false;

  static const String userCollectionName = 'users';
  static const String productCollectionName = 'products';
  static const String categoryCollectionName = 'categories';

  /// Initialize Firebase (Connection is automatic)
  static Future<void> connect() async {
    try {
      // In Firebase, "connecting" is instantaneous as it's just getting the instance.
      // We check if the app is initialized to be safe.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Initialiser la connexion Firestore
      // Note: Si votre projet Firebase s'appelle "flutter", le fichier de configuration
      // (google-services.json ou GoogleService-Info.plist) pointe déjà vers le bon projet.
      // Pour utiliser une base de données nommée "flutter", vous devez d'abord la créer
      // dans Firebase Console, puis utiliser: FirebaseFirestore.instanceFor(app: Firebase.app(), database: 'flutter')
      _db = FirebaseFirestore.instance;
      isConnected = true;
      print("✓ Firestore initialized successfully!");
      print("✓ Connexion à Firebase établie");
      print("ℹ️ Le projet Firebase est configuré via google-services.json / GoogleService-Info.plist");

      // Optional: Check connection by fetching a count (costs 1 read)
      try {
        AggregateQuerySnapshot countSnapshot = await db.collection(userCollectionName).count().get();
        print("✓ Users in database: ${countSnapshot.count}");
      } catch (e) {
        print("⚠️ Could not count users (might be offline): $e");
      }

    } catch (e) {
      isConnected = false;
      print("✗ Error connecting to Firestore: $e");
      rethrow;
    }
  }

  /// Create default users (Admin, Client, Vendeur) in Firestore
  static Future<void> createDefaultUsers() async {
    try {
      final usersRef = db.collection(userCollectionName);

      // Helper function to create user if not exists
      Future<void> createUserIfNotExists(String email, Map<String, dynamic> data) async {
        final query = await usersRef.where('email', isEqualTo: email).limit(1).get();

        if (query.docs.isEmpty) {
          // Add a new document with an auto-generated ID
          await usersRef.add(data);
          print("✓ Created user: $email");
        } else {
          print("ℹ️ User already exists: $email");
        }
      }

      await createUserIfNotExists('admin@admin.com', {
        'email': 'admin@admin.com',
        'password': 'admin123',
        'role': 'admin',
        'username': 'admin',
        'firstName': 'Admin',
        'lastName': 'User',
      });

      await createUserIfNotExists('client@client.com', {
        'email': 'client@client.com',
        'password': 'client123',
        'role': 'client',
        'username': 'client',
        'firstName': 'Client',
        'lastName': 'User',
      });

      await createUserIfNotExists('vendeur@vendeur.com', {
        'email': 'vendeur@vendeur.com',
        'password': 'vendeur123',
        'role': 'vendeur',
        'username': 'vendeur',
        'firstName': 'Vendeur',
        'lastName': 'User',
      });

    } catch (e) {
      print("⚠️ Error creating default users: $e");
    }
  }

  /// Get all vendors from Firestore
  static Future<List<Map<String, dynamic>>> _getVendeurs() async {
    try {
      final snapshot = await db.collection(userCollectionName)
          .where('role', isEqualTo: 'vendeur')
          .get();

      // We attach the document ID to the data so we can reference it later
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Store Firestore ID as _id for compatibility
        return data;
      }).toList();
    } catch (e) {
      print("⚠️ Error getting vendors: $e");
      return [];
    }
  }

  /// Sync products from DummyJSON to Firestore
  static Future<void> syncProductsFromFakeStore() async {
    try {
      final productRef = db.collection(productCollectionName);

      // Check if products already exist
      final countSnapshot = await productRef.count().get();
      if (countSnapshot.count! > 0) {
        print("ℹ️ Products already exist (${countSnapshot.count}), skipping import.");
        await _assignProductsToVendeurs();
        return;
      }

      final vendeurs = await _getVendeurs();
      if (vendeurs.isEmpty) {
        print("⚠️ No vendors found. Products will be created without owners.");
      }

      // --- FETCHING DATA FROM API (Kept your exact logic) ---
      final allProducts = <Map<String, dynamic>>[];
      int productIndex = 0;
      const int limitPerPage = 100;

      print("🔄 Fetching products from DummyJSON...");

      // Fetch Page 1 to get total
      final firstRes = await http.get(Uri.parse('https://dummyjson.com/products?limit=$limitPerPage&skip=0'));
      if (firstRes.statusCode != 200) throw Exception('API Error');

      final firstData = jsonDecode(firstRes.body);
      final int total = firstData['total'];
      final int pages = (total / limitPerPage).ceil();

      // Function to process a list of products
      void processProducts(List<dynamic> items) {
        for (final item in items) {
          final p = item as Map<String, dynamic>;

          // Assign Vendor logic
          String? vendeurId, vendeurEmail, vendeurName;
          if (vendeurs.isNotEmpty) {
            final v = vendeurs[productIndex % vendeurs.length];
            vendeurId = v['_id'];
            vendeurEmail = v['email'];
            vendeurName = '${v['firstName']} ${v['lastName']}'.trim();
            if (vendeurName!.isEmpty) vendeurName = v['username'];
          }

          // Image logic
          String imageUrl = p['thumbnail'] ?? '';
          if (p['images'] != null && (p['images'] as List).isNotEmpty) {
            imageUrl = (p['images'] as List)[0];
          }

          // Discount logic
          double discount = (p['discountPercentage'] as num?)?.toDouble() ??
              (5.0 + ((productIndex * 11 + 17) % 26)).roundToDouble();

          allProducts.add({
            'apiId': p['id'],
            'title': p['title'],
            'price': (p['price'] as num).toDouble(),
            'description': p['description'] ?? '',
            'category': p['category'] ?? '',
            'image': imageUrl,
            'brand': p['brand'],
            'stock': p['stock'],
            'discountPercentage': discount,
            'vendeurId': vendeurId,
            'vendeurEmail': vendeurEmail,
            'vendeurName': vendeurName,
            'rating': {
              'rate': (p['rating'] as num?)?.toDouble(),
              'count': 0,
            },
            'createdAt': FieldValue.serverTimestamp(), // Firestore Timestamp
          });
          productIndex++;
        }
      }

      processProducts(firstData['products']);

      // Fetch remaining pages
      for (int page = 1; page < pages; page++) {
        final skip = page * limitPerPage;
        final res = await http.get(Uri.parse('https://dummyjson.com/products?limit=$limitPerPage&skip=$skip'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          processProducts(data['products']);
        }
      }

      print("✓ Fetched ${allProducts.length} products. Uploading to Firestore...");

      // --- UPLOADING TO FIRESTORE (BATCHED) ---
      // Firestore batches are limited to 500 operations. We must chunk them.
      int uploadedCount = 0;
      const int batchSize = 450; // Safe margin below 500

      for (var i = 0; i < allProducts.length; i += batchSize) {
        final batch = db.batch();
        final end = (i + batchSize < allProducts.length) ? i + batchSize : allProducts.length;
        final chunk = allProducts.sublist(i, end);

        for (final product in chunk) {
          final docRef = productRef.doc(); // Create new ID
          batch.set(docRef, product);
        }

        await batch.commit();
        uploadedCount += chunk.length;
        print("  ✓ Uploaded batch: $uploadedCount / ${allProducts.length}");
      }

      print("🎉 SYNCHRONIZATION COMPLETE!");

    } catch (e) {
      print("✗ Error syncing products: $e");
    }
  }

  /// Assign existing products to vendors (Migration tool)
  static Future<void> _assignProductsToVendeurs() async {
    try {
      final vendeurs = await _getVendeurs();
      if (vendeurs.isEmpty) return;

      // Find products without vendorId
      final snapshot = await db.collection(productCollectionName)
          .where('vendeurId', isNull: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      print("🔄 Assigning ${snapshot.docs.length} orphaned products...");

      // We must use batches again for updates
      WriteBatch batch = db.batch();
      int count = 0;
      int opCount = 0;

      for (final doc in snapshot.docs) {
        final vendeur = vendeurs[count % vendeurs.length];

        batch.update(doc.reference, {
          'vendeurId': vendeur['_id'],
          'vendeurEmail': vendeur['email'],
          'vendeurName': vendeur['firstName'] ?? vendeur['username']
        });

        count++;
        opCount++;

        // Commit batch every 450 ops
        if (opCount >= 450) {
          await batch.commit();
          batch = db.batch(); // Start new batch
          opCount = 0;
        }
      }

      // Commit remaining
      if (opCount > 0) await batch.commit();

      print("✓ Products assigned.");

    } catch (e) {
      print("✗ Error assigning vendors: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByVendeurEmail(String email) async {
    try {
      final snapshot = await db.collection(productCollectionName)
          .where('vendeurEmail', isEqualTo: email)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Important: mapping ID back for UI
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update Product
  static Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await db.collection(productCollectionName).doc(productId).update(updates);
      return true;
    } catch (e) {
      print("✗ Update Error: $e");
      return false;
    }
  }

  /// Delete Product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await db.collection(productCollectionName).doc(productId).delete();
      return true;
    } catch (e) {
      print("✗ Delete Error: $e");
      return false;
    }
  }

  static void logout() {
    currentUser = null;
    // Firebase has its own auth, you can also call:
    // FirebaseAuth.instance.signOut();
  }

  // ========== ADMIN METHODS ==========

  /// Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await db.collection(userCollectionName).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("✗ Error getting users: $e");
      return [];
    }
  }

  /// Create a new user
  static Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      // Check if email already exists
      final existing = await db.collection(userCollectionName)
          .where('email', isEqualTo: userData['email'])
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return false; // Email already exists
      }

      await db.collection(userCollectionName).add(userData);
      return true;
    } catch (e) {
      print("✗ Error creating user: $e");
      return false;
    }
  }

  /// Update user
  static Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await db.collection(userCollectionName).doc(userId).update(updates);
      return true;
    } catch (e) {
      print("✗ Error updating user: $e");
      return false;
    }
  }

  /// Delete user
  static Future<bool> deleteUser(String userId) async {
    try {
      await db.collection(userCollectionName).doc(userId).delete();
      return true;
    } catch (e) {
      print("✗ Error deleting user: $e");
      return false;
    }
  }

  /// Get all categories
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final snapshot = await db.collection(categoryCollectionName)
          .orderBy('name')
          .get();
      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).toList();
      print("✓ ${categories.length} catégories trouvées dans la collection 'categories'");
      return categories;
    } catch (e) {
      // Si la collection n'existe pas ou est vide, ce n'est pas une erreur
      if (e.toString().contains('index') || e.toString().contains('orderBy')) {
        // Essayer sans orderBy si l'index n'existe pas
        try {
          final snapshot = await db.collection(categoryCollectionName).get();
          final categories = snapshot.docs.map((doc) {
            final data = doc.data();
            data['_id'] = doc.id;
            return data;
          }).toList();
          print("✓ ${categories.length} catégories trouvées (sans orderBy)");
          return categories;
        } catch (e2) {
          print("ℹ️ Collection 'categories' vide ou inexistante: $e2");
          return [];
        }
      }
      print("ℹ️ Collection 'categories' vide ou inexistante: $e");
      return [];
    }
  }

  /// Create category
  static Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    try {
      // Check if category name already exists
      final existing = await db.collection(categoryCollectionName)
          .where('name', isEqualTo: categoryData['name'])
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return false; // Category already exists
      }

      categoryData['createdAt'] = FieldValue.serverTimestamp();
      await db.collection(categoryCollectionName).add(categoryData);
      return true;
    } catch (e) {
      print("✗ Error creating category: $e");
      return false;
    }
  }

  /// Update category
  static Future<bool> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await db.collection(categoryCollectionName).doc(categoryId).update(updates);
      return true;
    } catch (e) {
      print("✗ Error updating category: $e");
      return false;
    }
  }

  /// Delete category
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await db.collection(categoryCollectionName).doc(categoryId).delete();
      return true;
    } catch (e) {
      print("✗ Error deleting category: $e");
      return false;
    }
  }

  /// Get all products (admin view)
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      print("🔄 Début du chargement des produits depuis Firebase...");
      
      // Charger tous les produits sans orderBy pour éviter les problèmes d'index
      final snapshot = await db.collection(productCollectionName).get();
      
      print("📊 ${snapshot.docs.length} documents trouvés dans la collection 'products'");
      
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        // Utiliser l'ID du document Firestore comme _id
        data['_id'] = doc.id;
        
        // Si mongoId existe, on peut le garder aussi
        if (data['mongoId'] == null) {
          data['mongoId'] = doc.id;
        }
        
        // S'assurer que tous les champs nécessaires existent
        if (data['category'] == null) {
          data['category'] = '';
        }
        if (data['title'] == null) {
          data['title'] = '';
        }
        if (data['price'] == null) {
          data['price'] = 0.0;
        }
        
        return data;
      }).toList();
      
      // Trier manuellement par createdAt si disponible, sinon par _id
      products.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate != null && bDate != null) {
          try {
            return (bDate as Comparable).compareTo(aDate);
          } catch (e) {
            // Si la comparaison échoue, trier par ID
            return (b['_id'] as String).compareTo(a['_id'] as String);
          }
        }
        // Trier par ID si pas de date
        return (b['_id'] as String).compareTo(a['_id'] as String);
      });
      
      print("✓ ${products.length} produits chargés et traités depuis Firebase");
      
      if (products.isNotEmpty) {
        print("📦 Exemple de produit chargé: ${products.first['title']} (catégorie: ${products.first['category']})");
      }
      
      return products;
    } catch (e, stackTrace) {
      print("✗ Erreur lors du chargement des produits: $e");
      print("Stack trace: $stackTrace");
      return [];
    }
  }

  /// Create product (admin)
  static Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      productData['createdAt'] = FieldValue.serverTimestamp();
      await db.collection(productCollectionName).add(productData);
      return true;
    } catch (e) {
      print("✗ Error creating product: $e");
      return false;
    }
  }

  /// Get statistics for admin dashboard
  static Future<Map<String, int>> getAdminStatistics() async {
    try {
      final usersSnapshot = await db.collection(userCollectionName).count().get();
      final productsSnapshot = await db.collection(productCollectionName).count().get();
      final categoriesSnapshot = await db.collection(categoryCollectionName).count().get();
      
      final clientsSnapshot = await db.collection(userCollectionName)
          .where('role', isEqualTo: 'client')
          .count()
          .get();
      final vendeursSnapshot = await db.collection(userCollectionName)
          .where('role', isEqualTo: 'vendeur')
          .count()
          .get();

      return {
        'totalUsers': usersSnapshot.count ?? 0,
        'totalProducts': productsSnapshot.count ?? 0,
        'totalCategories': categoriesSnapshot.count ?? 0,
        'totalClients': clientsSnapshot.count ?? 0,
        'totalVendeurs': vendeursSnapshot.count ?? 0,
      };
    } catch (e) {
      print("✗ Error getting statistics: $e");
      return {
        'totalUsers': 0,
        'totalProducts': 0,
        'totalCategories': 0,
        'totalClients': 0,
        'totalVendeurs': 0,
      };
    }
  }
}