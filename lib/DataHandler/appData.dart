import 'package:flutter/cupertino.dart';
import 'package:taxi_app/models/address.dart';

class AppData extends ChangeNotifier {
  //pickup and dropoff location method
  Address pickUpLocation, dropOffLocation;
  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners(); //broad changes to the user
  }

  void updateDropOffLocationAddress(Address dropOffddress) {
    dropOffLocation = dropOffddress;
    notifyListeners(); //broad changes to the user
  }
}
