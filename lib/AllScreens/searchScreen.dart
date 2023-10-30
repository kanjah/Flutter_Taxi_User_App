// ignore_for_file: avoid_unnecessary_containers, prefer_is_empty

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/Assistants/requestAssistant.dart';
import 'package:taxi_app/DataHandler/appData.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/models/address.dart';
import 'package:taxi_app/models/placePredictions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  //Text controllers
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();

  //initialize placePrediction list with an empty list
  List<PlacePredidctions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    //retrive address from Provider in appData.dart, if no address was found return null
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    pickUpTextEditingController.text = placeAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 215.0,
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black,
                    blurRadius: 6.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7))
              ]),

              //SET DROP OFF
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 25.0, top: 25.0, right: 25.0, bottom: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 5.0),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.arrow_back),
                        ),
                        const Center(
                          child: Text(
                            "Set Drop off",
                            style: TextStyle(
                                fontSize: 18.0, fontFamily: "Brand-Bold"),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    //Pickup Location
                    Row(
                      children: [
                        Image.asset("images/pickicon.png",
                            height: 16.0, width: 16.0),
                        const SizedBox(height: 18.0),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),

                              //textbox input
                              child: TextField(
                                controller: pickUpTextEditingController,
                                decoration: InputDecoration(
                                  hintText: "PickUp Location",
                                  fillColor: Colors.grey[400],
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                      left: 11.0, top: 8.0, bottom: 8.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10.0),

                    //Where to
                    Row(
                      children: [
                        Image.asset("images/desticon.png",
                            height: 16.0, width: 16.0),
                        const SizedBox(height: 18.0),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),

                              //textfield input
                              child: TextField(
                                onChanged: (val) //val is input from user
                                    {
                                  findPlace(val);
                                },
                                controller: dropOffTextEditingController,
                                decoration: InputDecoration(
                                  hintText: "Where to?",
                                  fillColor: Colors.grey[400],
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                      left: 11.0, top: 8.0, bottom: 8.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // display ListView with places
            (placePredictionList.length > 0)
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0.0),
                      itemBuilder: (context, index) {
                        return PredictionTile(
                          placePredictions: placePredictionList[index],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          DividerWidget(),
                      itemCount: placePredictionList.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

//add google place api
  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autocompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:so";

      var res = await RequestAssistant.getRequest(
          autocompleteUrl); //RequestAssistant.getRequest from requestAssistant.dart

      if (res == "Failed") {
        return;
      }

      if (res["status"] == "OK") //responce status returns OK
      {
        var predictions = res[
            "predictions"]; //predictions are as a result of res returning OK in json format

        //convert predictions(places) from json and store them in a list using PlacePrediction() from placePrediction.dart
        var placesList = (predictions as List)
            .map((e) => PlacePredidctions.fromJson(e))
            .toList();

        //add retrived places to list
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

//PREDICTION TILE FOR TILE PLACES DISPLAY
class PredictionTile extends StatelessWidget {
  const PredictionTile({Key key, this.placePredictions}) : super(key: key);
  final PlacePredidctions placePredictions;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(padding: const EdgeInsets.all(0.0)),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            const SizedBox(
              height: 10.0,
            ),
            Row(
              children: [
                const Icon(Icons.add_location),
                const SizedBox(
                  height: 14.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      Text(
                        placePredictions.main_text, //from placePRediction.dart
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        placePredictions
                            .secondary_text, //from placePrediction.dart
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10.0,
            ),
          ],
        ),
      ),
    );
  }

  //get users address method
  void getPlaceAddressDetails(String placeId, context) async {
    //show user progress message
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Setting Destination, Please wait.....",
          );
        });

    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    //Disable user progress message
    Navigator.pop(context);

    if (res == "Failed") {
      return;
    }

    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      //update dropoff address
      Provider.of<AppData>(context, listen: false)
          .updateDropOffLocationAddress(address);
      print("This is the Drop off Location ::");
      print(address.placeName);

      Navigator.pop(context, "obtainDirection");
    }
  }
}

/**
 * the latitude and logitude are obtained from the result>geometry>location>lat/lng
 * the documentation is from https://developers.google.com/maps/documentation/places/web-service/details
 */