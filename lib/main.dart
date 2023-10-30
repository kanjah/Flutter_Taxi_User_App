import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/AllScreens/logingScreen.dart';
import 'package:taxi_app/AllScreens/mainscreen.dart';
import 'package:taxi_app/AllScreens/registrationScreen.dart';
import 'dart:ui';

import 'DataHandler/appData.dart';

void main() async {
  //init firebase db
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

//create a "users" db reference to used to save users in registration.dart
DatabaseReference usersRef =
    FirebaseDatabase.instance.reference().child("users");

class MyApp extends StatelessWidget {
  //const MyApp({Key? key}) : super(key: key);
  // static const String idScreen = "mainScreen";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      //initialize change notifier in appData.dart
      create: (context) => AppData(), //initialize appData from appData.dart
      child: MaterialApp(
        title: 'Rider - App',
        theme: ThemeData(
            //fontFamily: "Brand Bold"
            ),

        //ROUTES
        //CHECKING IF THE USER IS LOGGED IN
        initialRoute: FirebaseAuth.instance.currentUser == null
            ? LoginScreen.idScreen
            : MainScreen.idScreen,

        routes: {
          RegistrationScreen.idScreen: (context) => RegistrationScreen(),
          LoginScreen.idScreen: (context) => LoginScreen(),
          MainScreen.idScreen: (context) => MainScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
