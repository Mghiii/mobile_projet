import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<String> _categories = [];
  Map<String, int> _categoryCounts = {};
  Map<String, String> _categoryIcons = {};

  // Couleurs pour chaque catégorie
  final Map<String, List<Color>> _categoryColors = {
    'smartphones': [Color(0xFF667EEA), Color(0xFF764BA2)],
    'laptops': [Color(0xFFF093FB), Color(0xFFF5576C)],
    'fragrances': [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    'skincare': [Color(0xFF43E97B), Color(0xFF38F9D7)],
    'groceries': [Color(0xFFFA709A), Color(0xFFFEE140)],
    'home-decoration': [Color(0xFF30CFD0), Color(0xFF330867)],
    'furniture': [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    'tops': [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
    'womens-dresses': [Color(0xFFFF8A80), Color(0xFFFF6B9D)],
    'womens-shoes': [Color(0xFFC471ED), Color(0xFFF64F59)],
    'mens-shirts': [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    'mens-shoes': [Color(0xFF96DEDA), Color(0xFF50C9C3)],
    'mens-watches': [Color(0xFFF09819), Color(0xFFEDDE5D)],
    'womens-watches': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    'womens-bags': [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    'womens-jewellery': [Color(0xFFFFD89B), Color(0xFF19547B)],
    'sunglasses': [Color(0xFF89F7FE), Color(0xFF66A6FF)],
    'automotive': [Color(0xFF2C3E50), Color(0xFF34495E)],
    'motorcycle': [Color(0xFFE74C3C), Color(0xFFC0392B)],
    'lighting': [Color(0xFFFFD700), Color(0xFFFFA500)],
  };

  // Icônes pour chaque catégorie
  final Map<String, IconData> _categoryIconMap = {
    'smartphones': Icons.smartphone,
    'laptops': Icons.laptop,
    'fragrances': Icons.spa,
    'skincare': Icons.face,
    'groceries': Icons.shopping_basket,
    'home-decoration': Icons.home,
    'furniture': Icons.chair,
    'tops': Icons.checkroom,
    'womens-dresses': Icons.woman,
    'womens-shoes': Icons.shopping_bag,
    'mens-shirts': Icons.person,
    'mens-shoes': Icons.shopping_bag_outlined,
    'mens-watches': Icons.watch,
    'womens-watches': Icons.watch_later,
    'womens-bags': Icons.shopping_bag,
    'womens-jewellery': Icons.diamond,
    'sunglasses': Icons.dark_mode,
    'automotive': Icons.directions_car,
    'motorcycle': Icons.two_wheeler,
    'lighting': Icons.lightbulb,
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await MongoDatabase.db
          .collection(MongoDatabase.productCollectionName)
          .get();
      final products = snapshot.docs.map((doc) => doc.data()).toList();

      // Extraire les catégories uniques et compter les produits
      final categoriesSet = <String>{};
      final categoryCounts = <String, int>{};

      for (var product in products) {
        final category = product['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categoriesSet.add(category);
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final categories = categoriesSet.toList()..sort();

      setState(() {
        _categories = categories;
        _categoryCounts = categoryCounts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Color> _getCategoryColors(String category) {
    // Normaliser le nom de la catégorie pour la recherche
    final normalizedCategory = category.toLowerCase().replaceAll(' ', '-');
    return _categoryColors[normalizedCategory] ??
        [Color(0xFF667EEA), Color(0xFF764BA2)];
  }

  IconData _getCategoryIcon(String category) {
    final normalizedCategory = category.toLowerCase().replaceAll(' ', '-');
    return _categoryIconMap[normalizedCategory] ?? Icons.category;
  }

  String _formatCategoryName(String category) {
    // Capitaliser chaque mot
    return category
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              )
            : _categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 100,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune catégorie disponible',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    color: Colors.blueAccent,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final count = _categoryCounts[category] ?? 0;
                        final colors = _getCategoryColors(category);
                        final icon = _getCategoryIcon(category);
                        final formattedName = _formatCategoryName(category);

                        return _buildCategoryCard(
                          category: category,
                          formattedName: formattedName,
                          count: count,
                          colors: colors,
                          icon: icon,
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required String formattedName,
    required int count,
    required List<Color> colors,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers ClientDashboard avec la catégorie sélectionnée
        Navigator.of(context).pushReplacementNamed(
          '/client',
          arguments: category,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Pattern décoratif en arrière-plan
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Contenu de la carte
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icône de la catégorie
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    // Nom et nombre de produits
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count ${count > 1 ? 'produits' : 'produit'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Effet de brillance
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
