import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  // Un ValueNotifier pour contenir la liste des produits favoris.
  final ValueNotifier<List<Map<String, dynamic>>> favorites = ValueNotifier([]);
  final ValueNotifier<List<String>> searchHistory = ValueNotifier([]);

  static const String _favoritesKey = 'favorites';
  static const String _searchHistoryKey = 'search_history';

  // Singleton pattern - constructeur privé
  FavoritesService._internal() {
    _loadFavorites();
    _loadSearchHistory();
  }

  // Charger les favoris depuis SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        favorites.value = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des favoris: $e");
    }
  }

  // Sauvegarder les favoris dans SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(favorites.value);
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde des favoris: $e");
    }
  }

  // Charger l'historique de recherche depuis SharedPreferences
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList(_searchHistoryKey);
      if (historyList != null) {
        searchHistory.value = historyList;
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'historique: $e");
    }
  }

  // Sauvegarder l'historique de recherche dans SharedPreferences
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, searchHistory.value);
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde de l'historique: $e");
    }
  }

  // Ajouter un produit aux favoris
  Future<void> addToFavorites(Map<String, dynamic> product) async {
    final currentFavorites = List<Map<String, dynamic>>.from(favorites.value);
    final productId = product['_id']?.toString() ?? product['id']?.toString();
    
    // Vérifier si le produit n'est pas déjà dans les favoris
    if (!currentFavorites.any((p) => 
        (p['_id']?.toString() ?? p['id']?.toString()) == productId)) {
      currentFavorites.add(product);
      favorites.value = currentFavorites;
      await _saveFavorites();
      debugPrint("❤️ Produit ajouté aux favoris: ${product['title']}");
    }
  }

  // Retirer un produit des favoris
  Future<void> removeFromFavorites(Map<String, dynamic> product) async {
    final currentFavorites = List<Map<String, dynamic>>.from(favorites.value);
    final productId = product['_id']?.toString() ?? product['id']?.toString();
    
    currentFavorites.removeWhere((p) => 
        (p['_id']?.toString() ?? p['id']?.toString()) == productId);
    favorites.value = currentFavorites;
    await _saveFavorites();
    debugPrint("💔 Produit retiré des favoris: ${product['title']}");
  }

  // Vérifier si un produit est dans les favoris
  bool isFavorite(Map<String, dynamic> product) {
    final productId = product['_id']?.toString() ?? product['id']?.toString();
    return favorites.value.any((p) => 
        (p['_id']?.toString() ?? p['id']?.toString()) == productId);
  }

  // Ajouter une recherche à l'historique
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final currentHistory = List<String>.from(searchHistory.value);
    
    // Retirer la recherche si elle existe déjà
    currentHistory.remove(query.trim());
    
    // Ajouter au début
    currentHistory.insert(0, query.trim());
    
    // Limiter à 20 recherches
    if (currentHistory.length > 20) {
      currentHistory.removeRange(20, currentHistory.length);
    }
    
    searchHistory.value = currentHistory;
    await _saveSearchHistory();
  }

  // Supprimer une recherche de l'historique
  Future<void> removeFromSearchHistory(String query) async {
    final currentHistory = List<String>.from(searchHistory.value);
    currentHistory.remove(query);
    searchHistory.value = currentHistory;
    await _saveSearchHistory();
  }

  // Vider l'historique de recherche
  Future<void> clearSearchHistory() async {
    searchHistory.value = [];
    await _saveSearchHistory();
  }

  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();

  factory FavoritesService() {
    return _instance;
  }
}
