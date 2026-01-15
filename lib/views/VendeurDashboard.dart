import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class VendeurDashboard extends StatefulWidget {
  const VendeurDashboard({super.key});

  @override
  State<VendeurDashboard> createState() => _VendeurDashboardState();
}

class _VendeurDashboardState extends State<VendeurDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String? _vendeurName;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    if (MongoDatabase.productCollection == null) {
      return;
    }

    final productId = product['_id'];
    if (productId == null) {
      return;
    }

    final success = await MongoDatabase.deleteProduct(productId);
    if (success) {
      _loadProducts(); // Recharger la liste
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['title']} supprimé avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Supprimer le produit',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${product['title']}" ?\nCette action est irréversible.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProducts() async {
    if (MongoDatabase.productCollection == null || MongoDatabase.currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final vendeurEmail = MongoDatabase.currentUser!['email']?.toString();
    if (vendeurEmail == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Récupérer le nom du vendeur
    final firstName = MongoDatabase.currentUser!['firstName']?.toString() ?? '';
    final lastName = MongoDatabase.currentUser!['lastName']?.toString() ?? '';
    _vendeurName = '$firstName $lastName'.trim();
    if (_vendeurName!.isEmpty) {
      _vendeurName = MongoDatabase.currentUser!['username']?.toString() ?? 'Vendeur';
    }

    // Récupérer les produits du vendeur
    final products = await MongoDatabase.getProductsByVendeurEmail(vendeurEmail);
    
    // Trier par date de création (les plus récents en premier)
    products.sort((a, b) {
      final aDate = a['createdAt'] as String?;
      final bDate = b['createdAt'] as String?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // Décroissant
    });

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic>? currentUser) {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête du drawer avec profil
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueAccent,
                  Colors.blue.shade700,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser != null
                      ? (currentUser['firstName'] != null || currentUser['lastName'] != null
                          ? '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}'.trim()
                          : currentUser['username'] ?? currentUser['email'] ?? 'Vendeur')
                      : 'Vendeur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?['email'] ?? 'email@example.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Section Profil
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blueAccent),
            title: const Text('Mon Profil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/vendeur-profile');
            },
          ),
          // Section Paramètres
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blueAccent),
            title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/vendeur-settings');
            },
          ),
          const Divider(color: Colors.grey),
          // Liens rapides
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Actions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.blueAccent),
            title: const Text('Ajouter un produit', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).pushNamed('/vendeur-add-product');
              if (result == true) {
                _loadProducts(); // Recharger les produits après ajout
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blueAccent),
            title: const Text('Accueil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(color: Colors.grey),
          // Déconnexion
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              MongoDatabase.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MongoDatabase.currentUser;
    
    return Scaffold(
      drawer: _buildDrawer(context, currentUser),
      appBar: AppBar(
        title: Text(_vendeurName != null ? 'Dashboard - $_vendeurName' : 'Vendeur Dashboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Ajouter un produit',
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed('/vendeur-add-product');
              if (result == true) {
                _loadProducts(); // Recharger les produits après ajout
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les produits',
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              MongoDatabase.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              )
            : MongoDatabase.productCollection == null || MongoDatabase.currentUser == null
                ? const Center(
                    child: Text(
                      'Base de données non connectée.\nLes produits ne peuvent pas être chargés.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : _products.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: Colors.blueAccent,
                        child: const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: Center(
                              child: Text(
                                'Aucun produit assigné.\nTirez vers le bas pour rafraîchir.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: Colors.blueAccent,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                color: Colors.grey.shade900,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_products.length} produit(s)',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.58,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  final p = _products[index];
                                  final rating = (p['rating'] as Map<String, dynamic>?) ?? {};
                                  final finalPrice = p['discountPercentage'] != null && p['price'] != null
                                      ? ((p['price'] as num) * (1 - (p['discountPercentage'] as num) / 100))
                                      : p['price'];

                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey.shade900,
                                          Colors.grey.shade800,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Image avec bouton supprimer
                                        Expanded(
                                          flex: 3,
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.grey.shade800,
                                                      Colors.grey.shade900,
                                                    ],
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                  child: p['image'] != null
                                                      ? Image.network(
                                                          p['image'],
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Container(
                                                              color: Colors.grey.shade800,
                                                              child: Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                                          loadingProgress.expectedTotalBytes!
                                                                      : null,
                                                                  strokeWidth: 2,
                                                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                                                    Colors.blueAccent,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (_, __, ___) => Container(
                                                            color: Colors.grey.shade800,
                                                            child: const Icon(
                                                              Icons.image_not_supported,
                                                              size: 40,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.shopping_bag,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                ),
                                              ),
                                              // Boutons d'action (modifier et supprimer)
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Bouton modifier
                                                    Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueAccent,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.blueAccent.withValues(alpha: 0.5),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                                        onPressed: () async {
                                                          final result = await Navigator.of(context).pushNamed(
                                                            '/vendeur-edit-product',
                                                            arguments: p,
                                                          );
                                                          if (result == true) {
                                                            _loadProducts(); // Recharger les produits après modification
                                                          }
                                                        },
                                                        padding: const EdgeInsets.all(8),
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'Modifier le produit',
                                                      ),
                                                    ),
                                                    // Bouton supprimer
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade600,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.red.withValues(alpha: 0.5),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                                        onPressed: () => _showDeleteDialog(context, p),
                                                        padding: const EdgeInsets.all(8),
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'Supprimer le produit',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Badge de réduction
                                              if (p['discountPercentage'] != null)
                                                Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.red.shade600,
                                                          Colors.red.shade700,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.red.withValues(alpha: 0.5),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      '-${p['discountPercentage']}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Rating badge
                                              if (rating['rate'] != null)
                                                Positioned(
                                                  bottom: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.6),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          size: 12,
                                                          color: Colors.amber,
                                                        ),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${rating['rate']}',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Informations du produit
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Titre et Marque
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (p['brand'] != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blueAccent.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          p['brand']!.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            color: Colors.blue.shade300,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    if (p['brand'] != null) const SizedBox(height: 4),
                                                    Text(
                                                      p['title'] ?? '',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Prix et Stock
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            if (p['discountPercentage'] != null)
                                                              Text(
                                                                '${p['price']} \$',
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  color: Colors.grey.shade500,
                                                                  decoration: TextDecoration.lineThrough,
                                                                ),
                                                              ),
                                                            Text(
                                                              '${finalPrice?.toStringAsFixed(2) ?? '-'} \$',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green.shade400,
                                                                shadows: [
                                                                  Shadow(
                                                                    color: Colors.green.withValues(alpha: 0.3),
                                                                    blurRadius: 4,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (p['stock'] != null)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: (p['stock'] as int) > 0
                                                                  ? Colors.green.withValues(alpha: 0.2)
                                                                  : Colors.red.withValues(alpha: 0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: (p['stock'] as int) > 0
                                                                    ? Colors.green
                                                                    : Colors.red,
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  Icons.check_circle,
                                                                  size: 10,
                                                                  color: (p['stock'] as int) > 0
                                                                      ? Colors.green
                                                                      : Colors.red,
                                                                ),
                                                                const SizedBox(width: 3),
                                                                Text(
                                                                  '${p['stock']}',
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: (p['stock'] as int) > 0
                                                                        ? Colors.green
                                                                        : Colors.red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
