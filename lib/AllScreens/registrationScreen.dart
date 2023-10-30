// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../allWidgets/progressDialog.dart';
import '../main.dart';
import 'logingScreen.dart';
import 'mainscreen.dart';
// import 'package:rider_app/AllScreens/loginScreen.dart';
// import 'package:rider_app/AllScreens/mainscreen.dart';
// import 'package:rider_app/main.dart';

// import '../allWidgets/progressDialog.dart';

class RegistrationScreen extends StatelessWidget {
  //RegistrationScreen({Key? key}) : super(key: key);

  static const String idScreen = "register"; //used to define roots

  //Form Controllers
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
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
                height: 20.0,
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
                "Register as a Rider",
                style: TextStyle(
                  fontSize: 24.0,
                  fontFamily: "Brand Bold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 1.0,
              ),

              // FORM INPUT FIELD
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    //NAME TEXTFIELD INPUT
                    const SizedBox(height: 1.0),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(fontSize: 14.0)),
                    ),

                    //PHONE INPUT TEXTFIELD
                    const SizedBox(height: 1.0),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: "Phone",
                          labelStyle: TextStyle(
                            fontSize: 14.0,
                          ),
                          hintStyle: TextStyle(fontSize: 14.0)),
                    ),

                    //EMAIL FORM INPUT FIELD
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

                    //REGISTER BUTTON
                    const SizedBox(height: 25.0),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder()),
                        child: const SizedBox(
                          height: 50.0,
                          child: Center(
                            child: Text(
                              "Register",
                              style: TextStyle(
                                  fontSize: 18.0, fontFamily: "Brand Bold"),
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (nameTextEditingController.text.length < 3) {
                            displayToastMessage(
                                "name must be more than three characters",
                                context);
                          } else if (!emailTextEditingController.text
                              .contains("@")) {
                            displayToastMessage(
                                "Email address isn not valid", context);
                          } else if (phoneTextEditingController.text.isEmpty) {
                            displayToastMessage(
                                "phone number is required", context);
                          } else if (passwordTextEditingController.text.length <
                              6) {
                            displayToastMessage(
                                "password must be more than 6 characters",
                                context);
                          } else {
                            registerNewUser(context);
                          }
                        })
                  ],
                ),
              ),

              // HAVE AN ACCOUNT SECTION
              TextButton(
                onPressed: () {
                  //send user to login screen
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: const Text(
                  "Already have an account? Login Here",
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

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; //authenticate user
  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: "Registering, Please wait...");
        });

    final User firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      // ignore: prefer_interpolation_to_compose_strings
      displayToastMessage("Error: " + errMsg.toString(), context);
    }))
        .user;
    if (firebaseUser != null) //user created
    {
      //save user into db using usersRef  from main.dart
      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim()
      };
      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage("User registered successfully", context);

      //re-direct user to main screen
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } else {
      //error occured display error msg
      Navigator.pop(context);
      displayToastMessage("New user Account has not been created.", context);
    }
  }

  //DISPLAY FLUTTER TOAST MESSAGE
  displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }
}
