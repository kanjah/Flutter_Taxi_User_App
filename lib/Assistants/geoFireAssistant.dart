//this will store the drivers plus their key ,lat, lang position as a list
import 'package:taxi_app/models/nearbyAvailableDrivers.dart';

class GeoFireAssistant {
  static List<NearbyAvailableDrivers> nearbyAvailableDriversList = [];

  //delete driver from list method
  static void removeDriverFromList(String key) {
    int index =
        nearbyAvailableDriversList.indexWhere((element) => element.key == key);
    nearbyAvailableDriversList.remove(index);
  }

  //update driver location when on the move method
  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver) {
    int index = nearbyAvailableDriversList
        .indexWhere((element) => element.key == driver.key);

    nearbyAvailableDriversList[index].latitude = driver.latitude;
    nearbyAvailableDriversList[index].longitude = driver.longitude;
  }
}
