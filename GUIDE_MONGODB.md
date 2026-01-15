# Guide de Configuration MongoDB

## Problème : Erreur "Base de données non connectée"

Si vous voyez cette erreur, MongoDB n'est pas correctement connecté. Voici les solutions :

## Solution 1 : Vérifier que MongoDB est démarré

### Sur macOS/Linux :
```bash
# Vérifier si MongoDB est en cours d'exécution
ps aux | grep mongod

# Si MongoDB n'est pas démarré, démarrez-le :
mongod
```

### Sur Windows :
- Ouvrez MongoDB Compass ou démarrez le service MongoDB depuis les Services Windows

## Solution 2 : Insérer les utilisateurs manuellement via MongoDB Compass

1. **Ouvrez MongoDB Compass**
2. **Connectez-vous** à votre base de données (ex: `No_SQL_tps`)
3. **Sélectionnez la base de données** `flutter`
4. **Cliquez sur la collection** `users`
5. **Cliquez sur "ADD DATA" → "Insert Document"**
6. **Copiez-collez ce JSON pour chaque utilisateur :**

### Utilisateur Admin :
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

### Utilisateur Client :
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

### Utilisateur Vendeur :
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

## Solution 3 : Utiliser le script MongoDB

1. Ouvrez MongoDB Compass
2. Dans la collection `users`, cliquez sur le terminal MongoDB (icône `>_`)
3. Copiez-collez le contenu du fichier `insert_users_mongodb.js`
4. Exécutez le script

## Solution 4 : Modifier l'URL de connexion

Si votre MongoDB n'est pas sur `localhost:27017`, modifiez l'URL dans `lib/services/database.dart` :

```dart
// Trouvez votre URL de connexion dans MongoDB Compass
// Exemple : mongodb://127.0.0.1:27017/flutter
// Ou : mongodb+srv://username:password@cluster.mongodb.net/flutter

String connectionString = "VOTRE_URL_ICI";
```

## Vérification

Après avoir inséré les utilisateurs, vous devriez voir 3 documents dans la collection `users` dans MongoDB Compass.

## Identifiants de connexion

- **Admin**: `admin@admin.com` / `admin123`
- **Client**: `client@client.com` / `client123`
- **Vendeur**: `vendeur@vendeur.com` / `vendeur123`
