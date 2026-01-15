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

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendeurName != null ? 'Dashboard - $_vendeurName' : 'Vendeur Dashboard'),
        actions: [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MongoDatabase.productCollection == null || MongoDatabase.currentUser == null
              ? const Center(
                  child: Text(
                    'Base de données non connectée.\nLes produits ne peuvent pas être chargés.',
                    textAlign: TextAlign.center,
                  ),
                )
              : _products.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: Center(
                            child: Text('Aucun produit assigné.\nTirez vers le bas pour rafraîchir.'),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_products.length} produit(s)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final p = _products[index];
                                final rating = (p['rating'] as Map<String, dynamic>?) ?? {};

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: ListTile(
                                    leading: p['image'] != null
                                        ? Image.network(
                                            p['image'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image_not_supported),
                                          )
                                        : const Icon(Icons.shopping_bag),
                                    title: Text(p['title'] ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (p['brand'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              'Marque: ${p['brand']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          p['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (p['category'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  p['category'],
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            if (p['category'] != null) const SizedBox(width: 8),
                                            if (p['discountPercentage'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '-${p['discountPercentage']}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (p['discountPercentage'] != null)
                                              Text(
                                                '${p['price'] ?? '-'} \$',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                  decoration: TextDecoration.lineThrough,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (p['discountPercentage'] != null) const SizedBox(width: 4),
                                            Text(
                                              p['discountPercentage'] != null && p['price'] != null
                                                  ? '${((p['price'] as num) * (1 - (p['discountPercentage'] as num) / 100)).toStringAsFixed(2)} \$'
                                                  : '${p['price'] ?? '-'} \$',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (p['stock'] != null)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.inventory_2,
                                                    size: 14,
                                                    color: (p['stock'] as int) > 0 
                                                        ? Colors.green 
                                                        : Colors.red,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Stock: ${p['stock']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: (p['stock'] as int) > 0 
                                                          ? Colors.green 
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                              ),
                                            if (rating['rate'] != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      size: 16, color: Colors.amber),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${rating['rate']}${rating['count'] != null ? ' (${rating['count']})' : ''}',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
