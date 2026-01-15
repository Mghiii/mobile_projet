# Données des utilisateurs à insérer dans MongoDB

## Utilisateurs par défaut

Voici les données des 3 utilisateurs qui seront automatiquement créés au démarrage de l'application :

### 1. Administrateur
```json
{
  "email": "admin@admin.com",
  "password": "admin123",
  "role": "admin",
  "username": "admin",
  "firstName": "Admin",
  "lastName": "User"
}
```

**Identifiants de connexion :**
- Email: `admin@admin.com`
- Mot de passe: `admin123`

---

### 2. Client
```json
{
  "email": "client@client.com",
  "password": "client123",
  "role": "client",
  "username": "client",
  "firstName": "Client",
  "lastName": "User"
}
```

**Identifiants de connexion :**
- Email: `client@client.com`
- Mot de passe: `client123`

---

### 3. Vendeur
```json
{
  "email": "vendeur@vendeur.com",
  "password": "vendeur123",
  "role": "vendeur",
  "username": "vendeur",
  "firstName": "Vendeur",
  "lastName": "User"
}
```

**Identifiants de connexion :**
- Email: `vendeur@vendeur.com`
- Mot de passe: `vendeur123`

---

## Insertion manuelle dans MongoDB (optionnel)

Si vous souhaitez insérer ces utilisateurs manuellement dans MongoDB, utilisez cette commande dans le shell MongoDB :

```javascript
use flutter

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
])
```

**Note:** L'application créera automatiquement ces utilisateurs au démarrage si ils n'existent pas déjà dans la base de données.
