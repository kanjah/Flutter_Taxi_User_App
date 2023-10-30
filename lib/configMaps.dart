import 'package:firebase_auth/firebase_auth.dart';

import 'models/allUsers.dart';

String mapKey = "AIzaSyCrQ1N2Cpz_Mj_SOnFWVZyoi73Lasxe7hQ";

//WILL BE USED BY assistantMethods.dart>getcurentOnlineUserInfo()
User firebaseUser; //from package:firebase_auth/firebase_auth.dart
Users
    userCurrentInfo; //will contain loggedin users info from models/allUsers.dart
