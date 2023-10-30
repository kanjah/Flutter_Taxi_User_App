/*This class will save all the suggesions into a listvies.
* secondary,main text and place_id documentation can be found in
*https://developers.google.com/maps/documentation/places/web-service/autocomplete
*/

class PlacePredidctions {
  String secondary_text;
  String main_text;
  String place_id;

  PlacePredidctions({this.secondary_text, this.main_text, this.place_id});
  PlacePredidctions.fromJson(Map<String, dynamic> json) {
    place_id = json["place_id"];
    main_text = json["structured_formatting"]["main_text"];
    secondary_text = json["structured_formatting"]["secondary_text"];
  }
}
