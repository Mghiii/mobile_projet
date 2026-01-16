import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';
import 'package:miniprojet/services/ShoppingCartService.dart';
import 'package:miniprojet/services/FavoritesService.dart';

class ClientDashboard extends StatefulWidget {
  final String? initialCategory;
  
  const ClientDashboard({super.key, this.initialCategory});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final ShoppingCartService _cartService = ShoppingCartService();
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isSearching = false;
  
  final int _itemsPerPage = 12;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is Map && args['search'] != null) {
          final searchQuery = args['search'] as String;
          _searchController.text = searchQuery;
          _searchQuery = searchQuery;
          _performSearch(searchQuery);
        } else if (args is String) {
          _selectedCategory = args;
          _filterByCategory(args);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!MongoDatabase.isConnected) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final snapshot = await MongoDatabase.db.collection(MongoDatabase.productCollectionName).get();
    final products = snapshot.docs.map((doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return data;
    }).toList();

    products.sort((a, b) {
      final aDate = a['createdAt'];
      final bDate = b['createdAt'];
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return (bDate as Comparable).compareTo(aDate);
    });

    final categoriesSet = <String>{};
    for (var product in products) {
      final category = product['category']?.toString();
      if (category != null && category.isNotEmpty) {
        categoriesSet.add(category);
      }
    }
    final categories = categoriesSet.toList()..sort();

    setState(() {
      _allProducts = products;
      _categories = categories;
      _selectedCategory = widget.initialCategory;
      if (widget.initialCategory != null) {
        _filteredProducts = _allProducts
            .where((p) => p['category']?.toString() == widget.initialCategory)
            .toList();
      } else {
        _filteredProducts = products;
      }
      _currentPage = 0;
      _isLoading = false;
    });
    
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      if (category == null) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) => p['category']?.toString() == category)
            .toList();
      }
      _currentPage = 0;
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _isSearching = false;
        _selectedCategory = null;
        _filteredProducts = _allProducts;
        _currentPage = 0;
      });
      return;
    }

    _favoritesService.addToSearchHistory(query);

    setState(() {
      _searchQuery = query.trim();
      _isSearching = true;
      _selectedCategory = null;
      
      _filteredProducts = _allProducts.where((product) {
        final title = (product['title'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final brand = (product['brand'] ?? '').toString().toLowerCase();
        final searchLower = query.toLowerCase();
        
        return title.contains(searchLower) ||
            description.contains(searchLower) ||
            category.contains(searchLower) ||
            brand.contains(searchLower);
      }).toList();
      
      _filteredProducts.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return (bDate as Comparable).compareTo(aDate);
      });
      
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> get _paginatedProducts {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredProducts.length);
    return _filteredProducts.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredProducts.length / _itemsPerPage).ceil();

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic>? currentUser) {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
                          : currentUser['username'] ?? currentUser['email'] ?? 'Utilisateur')
                      : 'Utilisateur',
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
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blueAccent),
            title: const Text('Mon Profil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blueAccent),
            title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          const Divider(color: Colors.grey),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Liens rapides',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
            title: const Text('Mon Panier', style: TextStyle(color: Colors.white)),
            trailing: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _cartService.cart,
              builder: (context, cartItems, child) {
                return cartItems.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/cart');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blueAccent),
            title: const Text('Accueil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.blueAccent),
            title: const Text('Catégories', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/categories');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.blueAccent),
            title: const Text('Favoris', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/favorites');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blueAccent),
            title: const Text('Historique', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/search-history');
            },
          ),
          const Divider(color: Colors.grey),
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
        title: const Text('Boutique'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _cartService.cart,
            builder: (context, cartItems, child) {
              return Badge(
                label: Text(cartItems.length.toString()),
                isLabelVisible: cartItems.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Voir le panier',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/cart');
                  },
                ),
              );
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
            : !MongoDatabase.isConnected
                ? const Center(
                    child: Text(
                      'Base de données non connectée.\nLes produits ne peuvent pas être chargés.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : _allProducts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: Colors.blueAccent,
                        child: const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: Center(
                              child: Text(
                                'Aucun produit disponible.\nTirez vers le bas pour rafraîchir.',
                                style: TextStyle(color: Colors.white),
      ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isSearching
                                          ? Colors.blueAccent
                                          : Colors.grey.shade700,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher un produit...',
                                      hintStyle: TextStyle(color: Colors.grey.shade500),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.blueAccent,
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _performSearch('');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      _performSearch(value);
                                    },
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        _performSearch('');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.history),
                                color: Colors.blueAccent,
                                tooltip: 'Historique de recherche',
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/search-history');
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.black,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('Tous', style: TextStyle(color: Colors.white)),
                                  selected: _selectedCategory == null && !_isSearching,
                                  selectedColor: Colors.blueAccent,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey.shade800,
                                  onSelected: (_) {
                                    _searchController.clear();
                                    _filterByCategory(null);
                                  },
                                  avatar: _selectedCategory == null && !_isSearching
                                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              ..._categories.map((category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category, style: const TextStyle(color: Colors.white)),
                                      selected: _selectedCategory == category,
                                      selectedColor: Colors.blueAccent,
                                      checkmarkColor: Colors.white,
                                      backgroundColor: Colors.grey.shade800,
                                      onSelected: (_) => _filterByCategory(category),
                                      avatar: _selectedCategory == category
                                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                '${_filteredProducts.length} produit(s)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_isSearching)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.search, size: 14, color: Colors.blueAccent),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Recherche: $_searchQuery',
                                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onDeleted: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.blueAccent),
                                  ),
                                )
                              else if (_selectedCategory != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    backgroundColor: Colors.grey.shade800,
                                    label: Text(
                                      'Catégorie: $_selectedCategory',
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    onDeleted: () => _filterByCategory(null),
                                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.black,
                            child: RefreshIndicator(
                              onRefresh: _loadProducts,
                              color: Colors.blueAccent,
                              child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _paginatedProducts.length,
                              itemBuilder: (context, index) {
                                final p = _paginatedProducts[index];
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
                                                                valueColor: AlwaysStoppedAnimation<Color>(
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
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(alpha: 0.7),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (p['discountPercentage'] != null)
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 5),
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
                                            Positioned(
                                              bottom: 10,
                                              right: 10,
                                              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                                                valueListenable: _favoritesService.favorites,
                                                builder: (context, favorites, child) {
                                                  final isFavorite = _favoritesService.isFavorite(p);
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                                        color: isFavorite ? Colors.red : Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        if (isFavorite) {
                                                          _favoritesService.removeFromFavorites(p);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('${p['title']} retiré des favoris'),
                                                              duration: const Duration(seconds: 2),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        } else {
                                                          _favoritesService.addToFavorites(p);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('${p['title']} ajouté aux favoris'),
                                                              duration: const Duration(seconds: 2),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      padding: const EdgeInsets.all(8),
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            if (rating['rate'] != null)
                                              Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 4),
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
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (p['brand'] != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
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
                                                              horizontal: 6, vertical: 3),
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _cartService.addToCart(p);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${p['title']} ajouté au panier!'),
                                                  duration: const Duration(seconds: 2),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                                            label: const Text(
                                              'Ajouter au panier',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              ),
                            ),
                          ),
                        ),
                        if (_totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade900,
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                  onPressed: _currentPage > 0
                                      ? () => _goToPage(_currentPage - 1)
                                      : null,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  _totalPages < 3 ? _totalPages : 3,
                                  (i) {
                                    int pageIndex;
                                    if (_currentPage < 2) {
                                      pageIndex = i;
                                    } else if (_currentPage >= _totalPages - 2) {
                                      pageIndex = _totalPages - 3 + i;
                                    } else {
                                      pageIndex = _currentPage - 1 + i;
                                    }
                                    
                                    pageIndex = pageIndex.clamp(0, _totalPages - 1);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: TextButton(
                                        onPressed: () => _goToPage(pageIndex),
                                        style: TextButton.styleFrom(
                                          backgroundColor: _currentPage == pageIndex
                                              ? Colors.blueAccent
                                              : Colors.grey.shade800,
                                          minimumSize: const Size(40, 40),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          '${pageIndex + 1}',
                                          style: TextStyle(
                                            color: _currentPage == pageIndex
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: _currentPage == pageIndex
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                                  onPressed: _currentPage < _totalPages - 1
                                      ? () => _goToPage(_currentPage + 1)
                                      : null,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
      ),
    );
  }
}
