import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class VendeurEditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const VendeurEditProductScreen({super.key, required this.product});

  @override
  State<VendeurEditProductScreen> createState() => _VendeurEditProductScreenState();
}

class _VendeurEditProductScreenState extends State<VendeurEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _ratingController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values
    _titleController = TextEditingController(text: widget.product['title']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.product['description']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.product['price']?.toString() ?? '');
    _discountController = TextEditingController(text: widget.product['discountPercentage']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product['stock']?.toString() ?? '');
    _brandController = TextEditingController(text: widget.product['brand']?.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product['category']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product['image']?.toString() ?? '');

    // Safely handle the rating map
    dynamic ratingData = widget.product['rating'];
    String initialRating = '';

    if (ratingData is Map) {
      initialRating = ratingData['rate']?.toString() ?? '';
    }
    _ratingController = TextEditingController(text: initialRating);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // UPDATED: Only check for currentUser. Firestore is always "connected".
    if (MongoDatabase.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // UPDATED: Firestore IDs are always Strings.
      final productId = widget.product['_id']?.toString();

      if (productId == null) {
        throw Exception('ID du produit introuvable');
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discount = double.tryParse(_discountController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final rating = double.tryParse(_ratingController.text) ?? 0.0;

      // Preserve existing rating count if possible
      int ratingCount = 0;
      if (widget.product['rating'] is Map) {
        ratingCount = widget.product['rating']['count'] ?? 0;
      }

      final updatedProduct = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'discountPercentage': discount,
        'stock': stock,
        'brand': _brandController.text.trim(),
        'category': _categoryController.text.trim().toLowerCase(),
        'image': _imageUrlController.text.trim(),
        'rating': {
          'rate': rating,
          'count': ratingCount,
        },
        // We do not update 'createdAt', 'vendeurId', etc.
      };

      // UPDATED: Calls the static method we defined in database.dart
      bool success = await MongoDatabase.updateProduct(productId, updatedProduct);

      if (!success) {
        throw Exception("Échec de la mise à jour dans Firestore");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit modifié avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le produit'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Titre du produit',
                    icon: Icons.title,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La description est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Prix (\$)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le prix est requis';
                            }
                            if (double.tryParse(value) == null || double.parse(value) <= 0) {
                              return 'Prix invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _discountController,
                          label: 'Réduction (%)',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final discount = double.tryParse(value);
                              if (discount == null || discount < 0 || discount > 100) {
                                return 'Réduction invalide';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _stockController,
                          label: 'Stock',
                          icon: Icons.inventory_2,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le stock est requis';
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 0) {
                              return 'Stock invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _ratingController,
                          label: 'Note (0-5)',
                          icon: Icons.star,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final rating = double.tryParse(value);
                              if (rating == null || rating < 0 || rating > 5) {
                                return 'Note invalide';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _brandController,
                    label: 'Marque',
                    icon: Icons.branding_watermark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _categoryController,
                    label: 'Catégorie',
                    icon: Icons.category,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La catégorie est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _imageUrlController,
                    label: 'URL de l\'image',
                    icon: Icons.image,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'URL de l\'image est requise';
                      }
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasScheme) {
                        return 'URL invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}