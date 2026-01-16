import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _vendeurs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterCategory = 'all';
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print("🔄 Chargement des données depuis Firebase...");
      }
      
      final products = await MongoDatabase.getAllProducts();
      final users = await MongoDatabase.getAllUsers();
      final vendeurs = users.where((u) => u['role'] == 'vendeur').toList();

      final categoriesSet = <String>{};
      for (var product in products) {
        final category = product['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categoriesSet.add(category);
        }
      }
      final categories = categoriesSet.toList()..sort();

      if (kDebugMode) {
        print("📊 Résultats du chargement:");
        print("   - ${products.length} produits");
        print("   - ${categories.length} catégories uniques");
        print("   - ${vendeurs.length} vendeurs");
        if (products.isNotEmpty) {
          print("   - Première catégorie: ${categories.isNotEmpty ? categories.first : 'N/A'}");
          print("   - Exemple produit: ${products.first['title'] ?? 'Sans titre'}");
        }
      }

      setState(() {
        _products = products;
        _vendeurs = vendeurs;
        _categories = categories;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        if (products.isEmpty) {
          print("⚠️ ATTENTION: Aucun produit trouvé dans Firebase!");
          print("   Vérifiez que la collection 'products' contient des données.");
        } else {
          print("✅ Données chargées avec succès!");
        }
      }
    } catch (e, stackTrace) {
      print("✗ Error loading data: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final title = (product['title'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        final brand = (product['brand'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) ||
            description.contains(query) ||
            brand.contains(query);
      }).toList();
    }

    if (_filterCategory != 'all') {
      filtered = filtered.where((product) => product['category'] == _filterCategory).toList();
    }

    return filtered;
  }

  void _showAddProductDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final brandController = TextEditingController();
    final stockController = TextEditingController();
    final discountController = TextEditingController();
    final imageController = TextEditingController();
    String? selectedVendeurId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Ajouter un produit', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix *',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Remise (%)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL de l\'image',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_vendeurs.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedVendeurId,
                    dropdownColor: Colors.grey.shade800,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Vendeur',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Aucun')),
                      ..._vendeurs.map((v) => DropdownMenuItem(
                            value: v['_id'],
                            child: Text(v['email'] ?? 'N/A'),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVendeurId = value;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty ||
                    stockController.text.trim().isEmpty ||
                    categoryController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final vendeur = selectedVendeurId != null
                    ? _vendeurs.firstWhere((v) => v['_id'] == selectedVendeurId)
                    : null;

                final productData = {
                  'title': titleController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                  'description': descriptionController.text.trim(),
                  'category': categoryController.text.trim(),
                  'brand': brandController.text.trim(),
                  'stock': int.tryParse(stockController.text.trim()) ?? 0,
                  'discountPercentage': discountController.text.trim().isNotEmpty
                      ? double.tryParse(discountController.text.trim())
                      : null,
                  'image': imageController.text.trim().isNotEmpty
                      ? imageController.text.trim()
                      : null,
                  'vendeurId': vendeur?['_id'],
                  'vendeurEmail': vendeur?['email'],
                  'vendeurName': vendeur != null
                      ? '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim()
                      : null,
                  'rating': {
                    'rate': 0.0,
                    'count': 0,
                  },
                };

                final success = await MongoDatabase.createProduct(productData);
                if (!context.mounted) return;
                Navigator.pop(context);

                if (success) {
                  _loadData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit créé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la création'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Créer', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final titleController = TextEditingController(text: product['title']?.toString() ?? '');
    final priceController = TextEditingController(text: product['price']?.toString() ?? '');
    final descriptionController = TextEditingController(text: product['description']?.toString() ?? '');
    final categoryController = TextEditingController(text: product['category']?.toString() ?? '');
    final brandController = TextEditingController(text: product['brand']?.toString() ?? '');
    final stockController = TextEditingController(text: product['stock']?.toString() ?? '');
    final discountController = TextEditingController(
        text: product['discountPercentage']?.toString() ?? '');
    final imageController = TextEditingController(text: product['image']?.toString() ?? '');
    String? selectedVendeurId = product['vendeurId']?.toString();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Modifier le produit', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix *',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Remise (%)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL de l\'image',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_vendeurs.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedVendeurId,
                    dropdownColor: Colors.grey.shade800,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Vendeur',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Aucun')),
                      ..._vendeurs.map((v) => DropdownMenuItem(
                            value: v['_id'],
                            child: Text(v['email'] ?? 'N/A'),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVendeurId = value;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty ||
                    stockController.text.trim().isEmpty ||
                    categoryController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final vendeur = selectedVendeurId != null
                    ? _vendeurs.firstWhere((v) => v['_id'] == selectedVendeurId)
                    : null;

                final updates = {
                  'title': titleController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                  'description': descriptionController.text.trim(),
                  'category': categoryController.text.trim(),
                  'brand': brandController.text.trim(),
                  'stock': int.tryParse(stockController.text.trim()) ?? 0,
                  'discountPercentage': discountController.text.trim().isNotEmpty
                      ? double.tryParse(discountController.text.trim())
                      : null,
                  'image': imageController.text.trim().isNotEmpty
                      ? imageController.text.trim()
                      : null,
                  'vendeurId': vendeur?['_id'],
                  'vendeurEmail': vendeur?['email'],
                  'vendeurName': vendeur != null
                      ? '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim()
                      : null,
                };

                final success = await MongoDatabase.updateProduct(product['_id'], updates);
                if (!context.mounted) return;
                Navigator.pop(context);

                if (success) {
                  _loadData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit modifié avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la modification'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Supprimer le produit', style: TextStyle(color: Colors.white)),
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
            onPressed: () async {
              final success = await MongoDatabase.deleteProduct(product['_id']);
              if (!context.mounted) return;
              Navigator.pop(context);

              if (success) {
                _loadData();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produit supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_products.length} produit(s) | ${_categories.length} catégorie(s)',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        if (_products.isEmpty)
                          TextButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Synchronisation des produits en cours...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              await MongoDatabase.syncProductsFromFakeStore();
                              _loadData();
                            },
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Synchroniser', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_categories.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            FilterChip(
                              label: const Text('Toutes', style: TextStyle(color: Colors.white)),
                              selected: _filterCategory == 'all',
                              selectedColor: Colors.blueAccent,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey.shade800,
                              onSelected: (_) {
                                setState(() {
                                  _filterCategory = 'all';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map((category) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category, style: const TextStyle(color: Colors.white)),
                                    selected: _filterCategory == category,
                                    selectedColor: Colors.blueAccent,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade800,
                                    onSelected: (_) {
                                      setState(() {
                                        _filterCategory = category;
                                      });
                                    },
                                  ),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade600),
                                const SizedBox(height: 16),
                                Text(
                                  _products.isEmpty 
                                      ? 'Aucun produit dans Firebase'
                                      : 'Aucun produit correspondant aux filtres',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                if (_products.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: ${_products.length} produit(s)',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_filteredProducts.length} sur ${_products.length} produit(s)',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: Colors.blueAccent,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.6,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final finalPrice = product['discountPercentage'] != null &&
                                        product['price'] != null
                                    ? ((product['price'] as num) *
                                        (1 - (product['discountPercentage'] as num) / 100))
                                    : product['price'];

                                return Card(
                                  color: Colors.grey.shade900,
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
                                                  top: Radius.circular(12),
                                                ),
                                                color: Colors.grey.shade800,
                                              ),
                                              child: product['image'] != null
                                                  ? ClipRRect(
                                                      borderRadius: const BorderRadius.vertical(
                                                        top: Radius.circular(12),
                                                      ),
                                                      child: Image.network(
                                                        product['image'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => const Icon(
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
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blueAccent, size: 18),
                                                    onPressed: () => _showEditProductDialog(product),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete,
                                                        color: Colors.red, size: 18),
                                                    onPressed: () => _showDeleteProductDialog(product),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['title'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${finalPrice?.toStringAsFixed(2) ?? '-'} \$',
                                                style: TextStyle(
                                                  color: Colors.green.shade400,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (product['stock'] != null)
                                                Text(
                                                  'Stock: ${product['stock']}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 10,
                                                  ),
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
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showAddProductDialog,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
