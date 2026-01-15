/*
import 'package:flutter/material.dart';
import 'package:miniprojet/services/shopping_cart_service.dart';
import 'package:miniprojet/services/database.dart';
import 'package:miniprojet/widgets/product_card.dart';
import 'package:miniprojet/views/shopping_cart_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final ShoppingCartService _cartService = ShoppingCartService();

  List<String> _categories = [];
  String? _selectedCategory;
  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchCategories();
    await _fetchProducts(page: 1);
  }

  Future<void> _fetchCategories() async {
    if (MongoDatabase.productCollection == null) return;
    try {
      final categories = await MongoDatabase.productCollection!.distinct('category');
      if (!mounted) return;
      setState(() {
        _categories = categories['values'].cast<String>()..sort();
        _categories.insert(0, 'Toutes les catégories');
        _selectedCategory = 'Toutes les catégories';
      });
    } catch (e) {
      // Gérer l'erreur
    }
  }

  Future<void> _fetchProducts({required int page, bool loadMore = false}) async {
    if (MongoDatabase.productCollection == null || (!_hasMoreProducts && loadMore)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final query = _selectedCategory == null || _selectedCategory == 'Toutes les catégories'
          ? where
          : where.eq('category', _selectedCategory);

      final products = await MongoDatabase.productCollection!
          .find(query.limit(_pageSize).skip((page - 1) * _pageSize))
          .toList();

      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _products.addAll(products);
        } else {
          _products = products;
        }
        _currentPage = page;
        _hasMoreProducts = products.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Client'),
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _cartService.cart,
            builder: (context, cartItems, child) {
              return Badge(
                label: Text(cartItems.length.toString()),
                isLabelVisible: cartItems.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/cart');
                  },
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildProductsGrid(),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
            _hasMoreProducts = true;
          });
          _fetchProducts(page: 1);
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(
          product: product,
          onAddToCart: () {
            _cartService.addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${product['title']} ajouté au panier!"),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 ? () => _fetchProducts(page: _currentPage - 1) : null,
            child: const Text('Précédent'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Page $_currentPage'),
          ),
          ElevatedButton(
            onPressed: _hasMoreProducts && !_isLoading ? () => _fetchProducts(page: _currentPage + 1, loadMore: false) : null,
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }
}
*/