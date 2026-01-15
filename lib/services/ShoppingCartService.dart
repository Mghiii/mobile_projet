import 'package:flutter/foundation.dart';

class ShoppingCartService {
  // Un ValueNotifier pour contenir la liste des produits dans le panier.
  final ValueNotifier<List<Map<String, dynamic>>> cart = ValueNotifier([]);

  // Méthode pour ajouter un produit au panier.
  void addToCart(Map<String, dynamic> product) {
    final currentCart = List<Map<String, dynamic>>.from(cart.value);
    currentCart.add(product);
    cart.value = currentCart;
    print("🛒 Produit ajouté au panier: ${product['title']}");
    print("Total d'articles dans le panier: ${cart.value.length}");
  }

  // Méthode pour vider le panier.
  void clearCart() {
    cart.value = [];
    print("Panier vidé.");
  }

  // Méthode pour supprimer un produit du panier.
  void removeFromCart(Map<String, dynamic> product) {
    final currentCart = List<Map<String, dynamic>>.from(cart.value);
    currentCart.removeWhere((p) => p['_id'] == product['_id']);
    cart.value = currentCart;
    print("🗑️ Produit supprimé du panier: ${product['title']}");
  }

  // Méthode pour calculer le prix total du panier.
  double getTotalPrice() {
    return cart.value.fold(0.0, (total, p) {
      final price = p['price'] as num? ?? 0;
      final discount = p['discountPercentage'] as num? ?? 0;
      return total + price * (1 - discount / 100);
    });
  }

  // Singleton pattern pour s'assurer qu'une seule instance du service existe.
  static final ShoppingCartService _instance = ShoppingCartService._internal();

  ShoppingCartService._internal();

  factory ShoppingCartService() {
    return _instance;
  }
}