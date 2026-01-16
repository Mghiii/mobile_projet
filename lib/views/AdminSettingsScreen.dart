import 'package:flutter/material.dart';
import 'package:miniprojet/services/database.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedLanguage = 'Français';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Compte
            _buildSectionTitle('Compte'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Modifier le profil',
                  subtitle: 'Gérer vos informations personnelles',
                  onTap: () {
                    Navigator.of(context).pushNamed('/admin-profile');
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Changer le mot de passe',
                  subtitle: 'Mettre à jour votre mot de passe',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Section Préférences
            _buildSectionTitle('Préférences'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications, color: Colors.red),
                  title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Recevoir des notifications', style: TextStyle(color: Colors.grey)),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeTrackColor: Colors.red,
                  activeThumbColor: Colors.white,
                ),
                const Divider(color: Colors.grey),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.red),
                  title: const Text('Mode sombre', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Activer le thème sombre', style: TextStyle(color: Colors.grey)),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                  activeTrackColor: Colors.red,
                  activeThumbColor: Colors.white,
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.red),
                  title: const Text('Langue', style: TextStyle(color: Colors.white)),
                  subtitle: Text(_selectedLanguage, style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    _showLanguageDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Section Administration
            _buildSectionTitle('Administration'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.storage,
                  title: 'Gérer la base de données',
                  subtitle: 'Synchroniser et gérer les données',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsTile(
                  icon: Icons.backup,
                  title: 'Sauvegarder les données',
                  subtitle: 'Créer une sauvegarde complète',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsTile(
                  icon: Icons.analytics,
                  title: 'Statistiques et rapports',
                  subtitle: 'Voir les statistiques détaillées',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Section Application
            _buildSectionTitle('Application'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'À propos',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Aide et support',
                  subtitle: 'Obtenir de l\'aide',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Politique de confidentialité',
                  subtitle: 'Lire notre politique',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Bouton de déconnexion
            ElevatedButton.icon(
              onPressed: () {
                MongoDatabase.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.red),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.white),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Choisir la langue', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'Français',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: Colors.red,
              ),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Français';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: Colors.red,
              ),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('À propos', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mini Projet E-commerce', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('Application de commerce électronique développée avec Flutter et Firebase.', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Panel d\'administration pour gérer les utilisateurs, catégories et produits.', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
