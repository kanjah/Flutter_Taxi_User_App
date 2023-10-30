import 'dart:async';
//import 'dart:js';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/AllScreens/searchScreen.dart';
import 'package:taxi_app/Assistants/assistantMethods.dart';
import 'package:taxi_app/allWidgets/divider.dart';
import 'package:taxi_app/allWidgets/progressDialog.dart';
import 'package:taxi_app/configMaps.dart';
import 'package:taxi_app/models/directDetails.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_geofire/flutter_geofire.dart';

import '../Assistants/geoFireAssistant.dart';
import '../DataHandler/appData.dart';
import '../models/nearbyAvailableDrivers.dart';
import 'logingScreen.dart';

class MainScreen extends StatefulWidget {
  MainScreen();
  static const String idScreen = "mainScreen "; //used to define roots
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with
        TickerProviderStateMixin // [with TickerProviderStateMixin] for switching btwn req and where2 screen

{
  Completer<GoogleMapController> _controllerGoogleMap = Completer();

  //will be used to create markers and other assets
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<
      ScaffoldState>(); //to be used in the gestruteDetector onPress & scafforl

//USED TO CALCULATE TRIP FARES (from models/directDetails.dart)
  DirectionDetails tripDirectionDetails;

//FOR DRAWINING POLYLINES ON MAP
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  var latLngBounds;

//bottom padding of google map
  double bottomPaddingofMap = 0;

//will be used to locte current user possition
  Position currentPosition;

  //SETTIING MARKERS ON THE MAP
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  // VARIABLES FOR SWITHING BETWEEN WHERE TO AND REQUEST SCREEN
  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;

  // USED TO CANCEL TRIP(drawer buttton on main screen)
  bool drawerOpen = true;

  //USED IN LOCATING NEARBY DRIVERS
  bool nearbyAvailableDriverKeysLoaded = false;

  //USED TO ADD CAR ICONS TO NEARBY DRIVERS
  BitmapDescriptor nearByIcon;

  //DATABASE REFERENCE
  DatabaseReference rideRequestRef;

  //GET ALL CURRENT ONLINE USERS INFO
  @override
  void initState() {
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  //SAVE RIDE & USERS INFO TO FIREBASE
  void saveRideRequest() {
    rideRequestRef = FirebaseDatabase.instance
        .reference()
        .child("Ride Requests")
        .push(); //makes a new ride request model

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      //will save pick location to firebase
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLockMap = {
      // save drop off location to firebase
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map rideInfoMap = {
      //save ride details to firebase
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLockMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName
    };

    rideRequestRef.set(rideInfoMap);
  }

  //CANCEL RIDE
  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  //RESET TRIP REQUEST()
  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRidecontainerHeight = 0;
      bottomPaddingofMap = 230.0;
      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  //METHOD FOR SWITHING BETWEEN WHERE SCREEN & REQUEST SCREEN
  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingofMap = 230.0;
      drawerOpen = false;
    });
  }

//VARIABLES FOR SWITCHING BETWEEN REQUEST & CANCEL RIDE HALF SCREENS
  double requestRidecontainerHeight = 0;

//METHOD FOR SWITCHING BTWN REQUEST RIDE & CANCEL RIDE
  void displayRequestRideContainer() {
    setState(() {
      requestRidecontainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingofMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  var geolocator = Geolocator();

//get users location method
  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    print("curentPosition accessed");

    print(currentPosition);

    LatLng latLatPosition = LatLng(position.latitude,
        position.longitude); // users current lat and long position

    print("latLatPosition accessed");
    print(latLatPosition);

    // move camera to current users position
    CameraPosition cameraPosition =
        new CameraPosition(target: latLatPosition, zoom: 14);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //geocoding searchCoodinatesAddress from assistAntMethods.dart and context from assistantMethods.dart seachcordianteaddress
    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);

    print("This is your Address ::" + address);

    initGeoFireListner();
  }

  //DEFAULT GOOGLE CAMERA POSITION
  static final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMaker();
    return Scaffold(
      key: scaffoldKey, //from GlobalKey above
      appBar: AppBar(
        title: const Text("Main Screen"),
      ),

      // Drawer, for hamburger menu in google maps
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              SizedBox(
                height: 165.0,
                child: DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset("images/user_icon.png",
                          height: 65.0, width: 65.0),
                      const SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Profile Name",
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand-Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Visit Profile")
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              const SizedBox(height: 12.0),

              //Drawer Body Controllers
              const ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              const ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              const ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "About",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              //SIGN OUT
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.history),
                  title: Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        //GOOGLE MAP
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingofMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,

            //current location marker(bluedot )
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,

            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingofMap = 300.0;
              });

              locatePosition(); //locate users current position
              print("locatePosition method clicked");
            },
          ),

          //HambergerButton for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,

            //RESET TRIP(when X on hamberger menu is clicked)
            child: GestureDetector(
              onTap: (() {
                if (drawerOpen) {
                  scaffoldKey.currentState?.openDrawer();
                } else {
                  resetApp();
                }
              }),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,

                  //SWITCH BTWN DRAWER MODES, WHEN OPENED OR NOT
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //SEARCH CONTAINER [searchContainerHeight described in displayRideDelailContainer above]
          //Where to Text box
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,

            //used for switching btw screens when one is active
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.0),
                    topRight: Radius.circular(18.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6.0),

                        //Hi there text
                        const Text(
                          "Hi, there, ",
                          style: TextStyle(fontSize: 12.0),
                        ),

                        //Where to text
                        const Text(
                          "Where to? ",
                          style: TextStyle(
                              fontSize: 20.0, fontFamily: "Brand-Bold"),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),

                        //Search Dropoff
                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchScreen()));

                            //obtainDirection is from searchScreen, getPlaceAddressDetails() > Navigator.pop()
                            if (res == "obtainDirection") {
                              displayRideDetailsContainer();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 6.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: const [
                                  //Search Drop off
                                  Icon(
                                    Icons.search,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Text("Search Drop off")
                                ],
                              ),
                            ),
                          ),
                        ),

                        // add home text
                        const SizedBox(height: 24.0),
                        Row(
                          children: [
                            const Icon(Icons.home, color: Colors.grey),
                            const SizedBox(width: 12.0),
                            Column(
                              children: [
                                //use provider method from assistantMethod.dart
                                Text(Provider.of<AppData>(context)
                                            .pickUpLocation !=
                                        null
                                    ? Provider.of<AppData>(context)
                                        .pickUpLocation
                                        .placeName
                                    : "Add Home"),
                                const SizedBox(height: 4.0),
                                const Text(
                                  "Your living home address",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                ),
                              ],
                            )
                          ],
                        ),

                        //Add work text
                        const SizedBox(height: 10.0),

                        DividerWidget(),

                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            const Icon(Icons.work, color: Colors.grey),
                            const SizedBox(width: 12.0),
                            Column(
                              children: const [
                                Text("Add Work"),
                                SizedBox(height: 4.0),
                                Text(
                                  "Your office address",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                ),
                              ],
                            )
                          ],
                        )
                      ]),
                ),
              ),
            ),
          ),

          //RIDE DETAILS CONTAINER
          //display ride fares/taxis/request button
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,

            //used for switching btw screens when one is active
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      //TAXI PNG & TRIP DISTANCE TEXT
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset("images/taxi.png",
                                  height: 70.0, width: 80.0),
                              const SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Car",
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontFamily: "Brand-Bold"),
                                  ),

                                  //SECOND PROCESS OF SETTING RIDE FARES
                                  Text(
                                    ((tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : ''), //DISPLAY DISTANCE TEXT HERE
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.grey),
                                  )
                                ],
                              ),

                              //DISPLAY TRIP COST
                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null)
                                    ? '\$${AssistantMethods.calculateFares(tripDirectionDetails)}'
                                    : ''),
                                style:
                                    const TextStyle(fontFamily: "Brand-Bold"),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 21.0,
                      ),

                      //CASH TEXT
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: const [
                            Icon(
                              FontAwesomeIcons.moneyCheckAlt,
                              size: 18.0,
                              color: Colors.black54,
                            ),
                            SizedBox(
                              width: 16.0,
                            ),
                            Text("Cash"),
                            SizedBox(width: 6.0),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black54,
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 24.0,
                      ),

                      //REQUEST BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder()),
                            child: Padding(
                              padding: const EdgeInsets.all(17.0),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      "Request",
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Icon(
                                      FontAwesomeIcons.taxi,
                                      color: Colors.white,
                                      size: 26.0,
                                    )
                                  ]),
                            ),
                            onPressed: () {
                              displayRequestRideContainer();
                            }),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          //REQUEST A RIDE
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7)),
                ],
              ),

              //REQUEST RIDE CONTAINER
              height: requestRidecontainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12.0,
                    ),

                    SizedBox(
                      width: double.infinity,

                      //ANIMATED TEXT
                      child: ColorizeAnimatedTextKit(
                        onTap: (() {}),
                        text: const [
                          "Requesting a Ride....",
                          "Please Wait....",
                          "Searching for a Driver..."
                        ],
                        textStyle: const TextStyle(
                            fontSize: 45.0, fontFamily: "Signatra"),
                        colors: const [
                          Colors.green,
                          Colors.purple,
                          Colors.pink,
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                        ],
                        textAlign: TextAlign.center,
                        alignment: AlignmentDirectional.topStart,
                      ),
                    ),
                    const SizedBox(
                      height: 22.0,
                    ),

                    //CANCEL RIDE BUTTON
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border:
                              Border.all(width: 2.0, color: Colors.grey[300]),
                        ),
                        child: const Icon(Icons.close, size: 26.0),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Cancell Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

//USED TO OBTAIN DIRECTIONS FROM INITIAL POINT TO DESTINATION
  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    //SHOW USER A PROGRESS DIALOG
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Please wait.....",
          );
        });

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    //FIRST PROCESS OF SETTING RIDE FARES
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print("This is Encoded Points ::");
    print(details.encodedPoints);

    //POLYLINES BEGIN
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates
        .clear(); //ensure pLinecoordinates are empty before adding new plinecoordinates

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        //convert pointLatLng to object
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    //POLYLINE INSTANCE

    polylineSet
        .clear(); //make sure polyline is empty before adding new polylines

    setState(() {
      Polyline polyline = Polyline(
          color: Colors.pink,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polylineSet.add(polyline);
    });

    //FIT POLYLINE TO MAP
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    //ADD MARKERS ON THE MAP

    //pickup location marker
    Marker pickUpLocMarker = Marker(
        markerId: MarkerId("pickUpId"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "my location"),
        position: pickUpLatLng);

    //drop off location marker
    Marker dropOffLocMarker = Marker(
        markerId: MarkerId("dropOffId"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "my destination"),
        position: dropOffLatLng);

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    //pick up location circle
    Circle pickUpLocCircle = Circle(
        circleId: CircleId("pickUpId"),
        fillColor: Colors.blueAccent,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent);

    //drop off location circle
    Circle dropOffLocCircle = Circle(
      circleId: CircleId("dropOffId"),
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  //FIND NEARBY DRIVERS IMPLEMENTATION METHOD
  void initGeoFireListner() {
    //availableDrivers are found in the realdabase>rules
    Geofire.initialize("availableDrivers");

    //searched for driver within 10k radius
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 10)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            //nearbyavailabledrivers from models>nearbyAvailableDrivers.dart
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key =
                map['key']; //key is from the driver(availableDrivers) from db
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];

            //add drivers to list
            //GeoFireAssistant from geoFireAssistant.dart
            GeoFireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              upddateAvailabeDriversOnMap();
            }
            break;

          case Geofire.onKeyExited: //when driver goes offline
            GeoFireAssistant.removeDriverFromList(map['key']);
            upddateAvailabeDriversOnMap();
            break;

          case Geofire.onKeyMoved: // when driver is on the move
            //nearbyavailabledrivers from models>nearbyAvailableDrivers.dart
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key =
                map['key']; //key is from the driver(availableDrivers) from db
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            upddateAvailabeDriversOnMap();
            break;

          case Geofire
              .onGeoQueryReady: // adds markers on the map for the available drivers
            upddateAvailabeDriversOnMap();

            break;
        }
      }

      setState(() {});
    });
  }

  //DISPLAY AVAILABLE DRIVERS ON THE MAP METHOD
  void upddateAvailabeDriversOnMap() {
    Set<Marker> tMakers = Set<Marker>();
    //get driver one at a time from NearbyAvailableDrivers
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);

      //apply markers
      Marker marker = Marker(
          markerId: MarkerId('driver${driver.key}'),
          position: driverAvailablePosition,
          icon: nearByIcon,
          // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),

          rotation: AssistantMethods.createRandomNumber(360));

      tMakers.add(marker);
    }
    setState(() {
      markersSet = tMakers;
    });
  }

  //CREATE CAR ICON MARKERS
  void createIconMaker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png")
          .then((value) {
        nearByIcon = value;
      });
    }
  }
}
