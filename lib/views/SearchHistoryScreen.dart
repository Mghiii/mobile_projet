import 'package:flutter/material.dart';
import 'package:miniprojet/services/FavoritesService.dart';

class SearchHistoryScreen extends StatelessWidget {
  const SearchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de recherche'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<List<String>>(
            valueListenable: favoritesService.searchHistory,
            builder: (context, history, child) {
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Vider l\'historique',
                onPressed: () {
                  _showClearHistoryDialog(context, favoritesService);
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: favoritesService.searchHistory,
          builder: (context, history, child) {
            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 100,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun historique',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vos recherches récentes apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final query = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      query,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        favoritesService.removeFromSearchHistory(query);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$query" supprimé de l\'historique'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Naviguer vers ClientDashboard avec la recherche
                      Navigator.of(context).pushReplacementNamed(
                        '/client',
                        arguments: {'search': query},
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    FavoritesService favoritesService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Vider l\'historique',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tout l\'historique de recherche ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              favoritesService.clearSearchHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historique vidé'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
