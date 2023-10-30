// ignore_for_file: use_build_context_synchronously, missing_return

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:taxi_app/AllScreens/registrationScreen.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
//import 'package:rider_app/AllScreens/registrationScreen.dart';
//import 'package:rider_app/allWidgets/progressDialog.dart';

import '../main.dart';
import 'mainscreen.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login"; //used to define routes

//Form Controllers
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              //LOGO
              const SizedBox(
                height: 35.0,
              ),
              const Image(
                image: AssetImage('images/logo.png'),
                width: 390.0,
                height: 250.0,
                alignment: Alignment.center,
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                "Login as a Rider",
                style: TextStyle(
                  fontSize: 24.0,
                  fontFamily: "Brand Bold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 5.0,
              ),

              //EMAIL FORM INPUT FIELD
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 1.0),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(fontSize: 14.0)),
                    ),

                    //PASSWORD FORM INPUT FIELD
                    const SizedBox(height: 1.0),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true, //hides input
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                    ),
                    const SizedBox(height: 25.0),

                    //LOGIN BUTTON
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder()),
                        child: const SizedBox(
                          height: 50.0,
                          child: Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                  fontSize: 18.0, fontFamily: "Brand Bold"),
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (!emailTextEditingController.text.contains("@")) {
                            displayToastMessage(
                                "Email address isn not valid", context);
                          } else if (passwordTextEditingController
                              .text.isEmpty) {
                            displayToastMessage(
                                "password field cannot be empty", context);
                          } else {
                            loginUser(context);
                          }
                        })
                  ],
                ),
              ),

              //DONT HAVE AN ACCOUNT SECTION
              TextButton(
                onPressed: () {
                  //direct to registration screen
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegistrationScreen.idScreen, (route) => false);
                },
                child: const Text(
                  "Do not have an account? Register Here",
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //LOGIN USER METHOD

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void loginUser(BuildContext context) async {
    //call the Progress Dialog
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Authenticating, please wait.....",
          );
        });
    // =>
    //     const AlertDialog(title: Text("Authenticating, please wait.....")));

    final User firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context); // incase of error stop the progressDialog
      displayToastMessage("Error:$errMsg", context);
    }))
        .user;

    if (firebaseUser != null) //user created
    {
      //check if user credential is in the db
      usersRef.child(firebaseUser.uid).once().then((DataSnapshot snap) {
        if (snap.value != null) {
          //re-direct user to main screen
          Navigator.pushNamedAndRemoveUntil(
              context, MainScreen.idScreen, (route) => false);

          displayToastMessage("login successfully", context);
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          displayToastMessage(
              "no user with those creds found, SignUp to continue", context);
        }
      });
    } else {
      //error occured display error msg
      Navigator.pop(context);
      displayToastMessage("Error cannot be signed in.", context);
    }
  }

  //DISPLAY FLUTTER TOAST MESSAGE
  displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }
}
