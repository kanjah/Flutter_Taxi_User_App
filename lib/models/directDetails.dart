class DirectionDetails {
  int distanceValue;
  int durationValue;
  String distanceText;
  String durationText;
  String encodedPoints; //will store coordinates

  DirectionDetails(
      {this.distanceText,
      this.distanceValue,
      this.durationText,
      this.durationValue,
      this.encodedPoints});
}

/**
 * the documentaion on the above can be obtained from
 * https://developers.google.com/maps/documentation/directions/get-directions#DirectionsResponses
 */
