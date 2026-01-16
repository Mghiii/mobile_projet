import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = MongoDatabase.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: currentUser == null
            ? const Center(
                child: Text(
                  'Aucun utilisateur connecté',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête du profil
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red,
                                  Colors.red.shade700,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}'.trim().isEmpty
                                ? currentUser['username'] ?? currentUser['email'] ?? 'Admin'
                                : '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Informations du profil
                    _buildSectionTitle('Informations personnelles'),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: currentUser['email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    if (currentUser['username'] != null)
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Nom d\'utilisateur',
                        value: currentUser['username'] ?? 'N/A',
                      ),
                    if (currentUser['username'] != null) const SizedBox(height: 12),
                    if (currentUser['firstName'] != null || currentUser['lastName'] != null)
                      _buildInfoCard(
                        icon: Icons.badge,
                        label: 'Nom complet',
                        value: '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}'.trim(),
                      ),
                    if (currentUser['firstName'] != null || currentUser['lastName'] != null)
                      const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.shield,
                      label: 'Rôle',
                      value: 'ADMIN',
                    ),
                    const SizedBox(height: 32),
                    // Statistiques
                    _buildSectionTitle('Statistiques'),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, int>>(
                      future: MongoDatabase.getAdminStatistics(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final stats = snapshot.data ?? {};
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.people,
                                label: 'Utilisateurs',
                                value: '${stats['totalUsers'] ?? 0}',
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.inventory_2,
                                label: 'Produits',
                                value: '${stats['totalProducts'] ?? 0}',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, int>>(
                      future: MongoDatabase.getAdminStatistics(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.category,
                                label: 'Catégories',
                                value: '${stats['totalCategories'] ?? 0}',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.shopping_bag,
                                label: 'Clients',
                                value: '${stats['totalClients'] ?? 0}',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade300,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
