import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class MongoDatabase {
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

  static Future<void> connect() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _db = FirebaseFirestore.instance;
      isConnected = true;
      print("✓ Firestore initialized successfully!");

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

  static Future<void> createDefaultUsers() async {
    try {
      final usersRef = db.collection(userCollectionName);

      Future<void> createUserIfNotExists(String email, Map<String, dynamic> data) async {
        final query = await usersRef.where('email', isEqualTo: email).limit(1).get();

        if (query.docs.isEmpty) {
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

  static Future<List<Map<String, dynamic>>> _getVendeurs() async {
    try {
      final snapshot = await db.collection(userCollectionName)
          .where('role', isEqualTo: 'vendeur')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("⚠️ Error getting vendors: $e");
      return [];
    }
  }

  static Future<void> syncProductsFromFakeStore() async {
    try {
      final productRef = db.collection(productCollectionName);

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

      final allProducts = <Map<String, dynamic>>[];
      int productIndex = 0;
      const int limitPerPage = 100;

      print("🔄 Fetching products from DummyJSON...");

      final firstRes = await http.get(Uri.parse('https://dummyjson.com/products?limit=$limitPerPage&skip=0'));
      if (firstRes.statusCode != 200) throw Exception('API Error');

      final firstData = jsonDecode(firstRes.body);
      final int total = firstData['total'];
      final int pages = (total / limitPerPage).ceil();

      void processProducts(List<dynamic> items) {
        for (final item in items) {
          final p = item as Map<String, dynamic>;

          String? vendeurId, vendeurEmail, vendeurName;
          if (vendeurs.isNotEmpty) {
            final v = vendeurs[productIndex % vendeurs.length];
            vendeurId = v['_id'];
            vendeurEmail = v['email'];
            vendeurName = '${v['firstName']} ${v['lastName']}'.trim();
            if (vendeurName!.isEmpty) vendeurName = v['username'];
          }

          String imageUrl = p['thumbnail'] ?? '';
          if (p['images'] != null && (p['images'] as List).isNotEmpty) {
            imageUrl = (p['images'] as List)[0];
          }

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
            'createdAt': FieldValue.serverTimestamp(),
          });
          productIndex++;
        }
      }

      processProducts(firstData['products']);

      for (int page = 1; page < pages; page++) {
        final skip = page * limitPerPage;
        final res = await http.get(Uri.parse('https://dummyjson.com/products?limit=$limitPerPage&skip=$skip'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          processProducts(data['products']);
        }
      }

      print("✓ Fetched ${allProducts.length} products. Uploading to Firestore...");

      int uploadedCount = 0;
      const int batchSize = 450;

      for (var i = 0; i < allProducts.length; i += batchSize) {
        final batch = db.batch();
        final end = (i + batchSize < allProducts.length) ? i + batchSize : allProducts.length;
        final chunk = allProducts.sublist(i, end);

        for (final product in chunk) {
          final docRef = productRef.doc();
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

  static Future<void> _assignProductsToVendeurs() async {
    try {
      final vendeurs = await _getVendeurs();
      if (vendeurs.isEmpty) return;

      final snapshot = await db.collection(productCollectionName)
          .where('vendeurId', isNull: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      print("🔄 Assigning ${snapshot.docs.length} orphaned products...");

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

        if (opCount >= 450) {
          await batch.commit();
          batch = db.batch();
          opCount = 0;
        }
      }

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
        data['_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await db.collection(productCollectionName).doc(productId).update(updates);
      return true;
    } catch (e) {
      print("✗ Update Error: $e");
      return false;
    }
  }

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
  }

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

  static Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final existing = await db.collection(userCollectionName)
          .where('email', isEqualTo: userData['email'])
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return false;
      }

      await db.collection(userCollectionName).add(userData);
      return true;
    } catch (e) {
      print("✗ Error creating user: $e");
      return false;
    }
  }

  static Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await db.collection(userCollectionName).doc(userId).update(updates);
      return true;
    } catch (e) {
      print("✗ Error updating user: $e");
      return false;
    }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      await db.collection(userCollectionName).doc(userId).delete();
      return true;
    } catch (e) {
      print("✗ Error deleting user: $e");
      return false;
    }
  }

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
      if (e.toString().contains('index') || e.toString().contains('orderBy')) {
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

  static Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final existing = await db.collection(categoryCollectionName)
          .where('name', isEqualTo: categoryData['name'])
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return false;
      }

      categoryData['createdAt'] = FieldValue.serverTimestamp();
      await db.collection(categoryCollectionName).add(categoryData);
      return true;
    } catch (e) {
      print("✗ Error creating category: $e");
      return false;
    }
  }

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

  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await db.collection(categoryCollectionName).doc(categoryId).delete();
      return true;
    } catch (e) {
      print("✗ Error deleting category: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      print("🔄 Début du chargement des produits depuis Firebase...");
      
      final snapshot = await db.collection(productCollectionName).get();
      
      print("📊 ${snapshot.docs.length} documents trouvés dans la collection 'products'");
      
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        
        if (data['mongoId'] == null) {
          data['mongoId'] = doc.id;
        }
        
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
      
      products.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate != null && bDate != null) {
          try {
            return (bDate as Comparable).compareTo(aDate);
          } catch (e) {
            return (b['_id'] as String).compareTo(a['_id'] as String);
          }
        }
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