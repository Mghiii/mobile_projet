// Script MongoDB pour insérer les 3 utilisateurs
// Exécuter dans MongoDB Compass ou MongoDB Shell

use('flutter');

db.users.insertMany([
  {
    email: "admin@admin.com",
    password: "admin123",
    role: "admin",
    username: "admin",
    firstName: "Admin",
    lastName: "User"
  },
  {
    email: "client@client.com",
    password: "client123",
    role: "client",
    username: "client",
    firstName: "Client",
    lastName: "User"
  },
  {
    email: "vendeur@vendeur.com",
    password: "vendeur123",
    role: "vendeur",
    username: "vendeur",
    firstName: "Vendeur",
    lastName: "User"
  }
]);

print("✓ 3 utilisateurs créés avec succès!");
