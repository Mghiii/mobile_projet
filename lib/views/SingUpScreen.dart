import 'package:flutter/material.dart';
import 'package:miniprojet/widgets/TextFieldExe.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("images/singup.png", height: 300,),
              SizedBox(height: 20),
              CustomTextFieldExe(
                controller: userNameController,
                labelText: "Username",
                icon: Icons.person,
              ),
              SizedBox(height: 15),
              CustomTextFieldExe(
                controller: firstNameController,
                labelText: "First Name",
                icon: Icons.face,
              ),
              SizedBox(height: 15),
              CustomTextFieldExe(
                controller: lastNameController,
                labelText: "Last Name",
                icon: Icons.badge,
              ),
              SizedBox(height: 15),
              CustomTextFieldExe(
                controller: emailController,
                labelText: "Email",
                icon: Icons.email,
              ),
              SizedBox(height: 15),
              CustomTextFieldExe(
                controller: pwdController,
                labelText: "Password",
                icon: Icons.password,
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: Text("Sing Up",style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),),),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("You have an account ?", style: TextStyle(fontSize: 14,color: Colors.white)),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () {},
                    child: Text("Login here", style: TextStyle(fontSize: 14, color: Colors.blueAccent)),
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
