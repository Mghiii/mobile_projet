import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';
import 'package:miniprojet/views/AdminUsersScreen.dart';
import 'package:miniprojet/views/AdminCategoriesScreen.dart';
import 'package:miniprojet/views/AdminProductsScreen.dart';
import 'package:miniprojet/views/AdminProfileScreen.dart';
import 'package:miniprojet/views/AdminSettingsScreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Map<String, int> _statistics = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });
    final stats = await MongoDatabase.getAdminStatistics();
    setState(() {
      _statistics = stats;
      _isLoadingStats = false;
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
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser != null
                      ? (currentUser['firstName'] != null || currentUser['lastName'] != null
                          ? '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}'.trim()
                          : currentUser['username'] ?? currentUser['email'] ?? 'Admin')
                      : 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?['email'] ?? 'admin@admin.com',
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
              Navigator.of(context).pushNamed('/admin-profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blueAccent),
            title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/admin-settings');
            },
          ),
          const Divider(color: Colors.grey),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Gestion',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blueAccent),
            title: const Text('Utilisateurs', style: TextStyle(color: Colors.white)),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.blueAccent),
            title: const Text('Catégories', style: TextStyle(color: Colors.white)),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.blueAccent),
            title: const Text('Produits', style: TextStyle(color: Colors.white)),
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2;
              });
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

  Widget _buildStatisticsCard() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(
            icon: Icons.people,
            label: 'Utilisateurs',
            value: '${_statistics['totalUsers'] ?? 0}',
            color: Colors.blueAccent,
          ),
          _buildStatCard(
            icon: Icons.inventory_2,
            label: 'Produits',
            value: '${_statistics['totalProducts'] ?? 0}',
            color: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.category,
            label: 'Catégories',
            value: '${_statistics['totalCategories'] ?? 0}',
            color: Colors.orange,
          ),
          _buildStatCard(
            icon: Icons.shopping_bag,
            label: 'Clients',
            value: '${_statistics['totalClients'] ?? 0}',
            color: Colors.purple,
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return AdminUsersScreen(onUserChanged: _loadStatistics);
      case 1:
        return AdminCategoriesScreen();
      case 2:
        return AdminProductsScreen();
      default:
        return AdminUsersScreen(onUserChanged: _loadStatistics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MongoDatabase.currentUser;

    return Scaffold(
      drawer: _buildDrawer(context, currentUser),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _loadStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              MongoDatabase.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: _selectedIndex == 0
            ? Column(
                children: [
                  _buildStatisticsCard(),
                  Expanded(
                    child: _buildCurrentScreen(),
                  ),
                ],
              )
            : _buildCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Produits',
          ),
        ],
      ),
    );
  }
}
