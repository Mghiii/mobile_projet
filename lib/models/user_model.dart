import 'package:mongo_dart/mongo_dart.dart';

enum UserRole { client, vendeur, admin }

class User {
  final ObjectId id;
  final String email;
  final String password;
  final UserRole role;

  User({required this.id, required this.email, required this.password, required this.role});

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'password': password,
      'role': role.toString().split('.').last,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'],
      email: map['email'],
      password: map['password'],
      role: UserRole.values.firstWhere((e) => e.toString() == 'UserRole.' + map['role']),
    );
  }
}

class Client extends User {
  Client({required ObjectId id, required String email, required String password})
      : super(id: id, email: email, password: password, role: UserRole.client);
}

class Vendeur extends User {
  Vendeur({required ObjectId id, required String email, required String password})
      : super(id: id, email: email, password: password, role: UserRole.vendeur);
}
