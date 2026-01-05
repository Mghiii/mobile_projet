import 'package:flutter/material.dart';
import 'package:miniprojet/widgets/TextFieldExe.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("images/login.png"),
              SizedBox(height: 20),
              CustomTextFieldExe(controller: _emailController, labelText: "Email", icon: Icons.email),
              SizedBox(height: 10,),
              CustomTextFieldExe(controller: _pwdController, labelText: "Password", icon: Icons.password, obscure: true,),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: Text("Login",style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),),),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account ?", style: TextStyle(fontSize: 14,color: Colors.white)),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () {},
                    child: Text("Sign up here", style: TextStyle(fontSize: 14, color: Colors.blueAccent)),
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
