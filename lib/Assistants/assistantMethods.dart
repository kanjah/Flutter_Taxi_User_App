import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/Assistants/requestAssistant.dart';
import 'package:taxi_app/DataHandler/appData.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/models/directDetails.dart';

import '../models/address.dart';
import '../models/allUsers.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    // ignore: unused_local_variable
    String st1, st2, st3, st4;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

/*user RequestAssistant() from requestAssistant.dart
* check if response is sucessfull, then store the data
*to placeAddress
*/
    var response = await RequestAssistant.getRequest(url);
    if (response != "Failed") {
      st1 = response["results"][0]["address_components"][0]
          ["long_name"]; //house/flat number

      st2 = response["results"][0]["address_components"][1]
          ["long_name"]; //street number

      st3 =
          response["results"][0]["address_components"][5]["long_name"]; // city

      st4 = response["results"][0]["address_components"][6]
          ["long_name"]; // country

      // ignore: prefer_interpolation_to_compose_strings
      placeAddress = st1 + ", " + st2 + ", " + st3 + " ," + st4;

//user pickup address from address.dart
      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return placeAddress;
  }

//FOR GOOGLE PLACE API DRAWING DIRECTIONS
/* add picking and dropping points */
  static Future<DirectionDetails> obtainPlaceDirectionDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == "Failed") {
      return null;
    }
    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints =
        res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText =
        res["routes"][0]["legs"][0]["distance"]["text"];

    directionDetails.distanceValue =
        res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText =
        res["routes"][0]["legs"][0]["duration"]["text"];

    directionDetails.durationValue =
        res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  //CALCULATE RIDE FARES IN USD & KM
  static int calculateFares(DirectionDetails directionDetails) {
    double timeTraveledFare =
        (directionDetails.durationValue / 60) * 0.02; //6osec == 1min

    double distanceTravedFare =
        (directionDetails.distanceValue / 1000) * 0.20; //1000m == 1km

    double totalFareAmount = timeTraveledFare + distanceTravedFare;

    //CONVERT TO LOCAL CURRENCY
    //double totlaLocalFare= totalFare * "Local Currency";

    return totalFareAmount.truncate();
  }

  //CONNECT TO FIREBASE AND FETCH USERS WHO ARE LOGGED IN
  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser.uid;
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapShot) {
      if (dataSnapShot.value != null) {
        userCurrentInfo = Users.fromSnapshot(dataSnapShot);
      }
    });
  }

  //Random number generator method for apply marker in mainscreen.dart
  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }
} 



/**
 * documentation found in 
 * https://developers.google.com/maps/documentation/directions/overview
 */


//sample results in json format as used to return placeAddress
/**
  "results" : [
    {
      "long_name": "279",
      "short_name" : "279",
      "types" : [" street_number"]
    }
    "formated_address": "279 Bedford Ave, Brooklyn,NY 11211, USA

    "address_components" : [
      {
        "long_name" : "NewYork",
        "short_name" : "NY"
      }
    ]
  ]
 */

