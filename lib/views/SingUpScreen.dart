import 'package:flutter/material.dart';
import 'package:miniprojet/widgets/TextFieldExe.dart';
import 'package:miniprojet/services/database.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;

class Singupscreen extends StatefulWidget {
  const Singupscreen({super.key});

  @override
  State<Singupscreen> createState() => _SingupscreenState();
}

class _SingupscreenState extends State<Singupscreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  String selectedRole = 'client'; // Par défaut client
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (MongoDatabase.userCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de base de données. Veuillez redémarrer l\'application.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (emailController.text.isEmpty || 
        pwdController.text.isEmpty ||
        userNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si l'email existe déjà
      var existingUser = await MongoDatabase.userCollection.findOne({
        'email': emailController.text.trim(),
      });

      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cet email est déjà utilisé'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Créer le nouvel utilisateur
      await MongoDatabase.userCollection.insert({
        '_id': ObjectId(),
        'email': emailController.text.trim(),
        'password': pwdController.text, // You should hash this password
        'role': selectedRole,
        'username': userNameController.text,
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès! Veuillez vous connecter.'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers le login après un délai
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("images/singup.png", height: 300,),
              const SizedBox(height: 20),
              CustomTextFieldExe(
                controller: userNameController,
                labelText: "Username",
                icon: Icons.person,
              ),
              const SizedBox(height: 15),
              CustomTextFieldExe(
                controller: firstNameController,
                labelText: "First Name",
                icon: Icons.face,
              ),
              const SizedBox(height: 15),
              CustomTextFieldExe(
                controller: lastNameController,
                labelText: "Last Name",
                icon: Icons.badge,
              ),
              const SizedBox(height: 15),
              CustomTextFieldExe(
                controller: emailController,
                labelText: "Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 15),
              CustomTextFieldExe(
                controller: pwdController,
                labelText: "Password",
                icon: Icons.password,
                obscure: true,
              ),
              const SizedBox(height: 15),
              // Sélecteur de rôle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButton<String>(
                  value: selectedRole,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'client',
                      child: Text('Client'),
                    ),
                    DropdownMenuItem(
                      value: 'vendeur',
                      child: Text('Vendeur'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedRole = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || MongoDatabase.userCollection == null ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                ),
              ),
              if (MongoDatabase.userCollection == null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Database not connected. Please restart the app.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("You have an account ?", style: TextStyle(fontSize: 14,color: Colors.white)),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text("Login here", style: TextStyle(fontSize: 14, color: Colors.blueAccent)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
