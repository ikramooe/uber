import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tProject/brand-colors.dart';
import 'package:tProject/datamodels/datadetails.dart';
import 'package:tProject/datamodels/nearbydriver.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/helpers/firehelper.dart';
import 'package:tProject/scenes/points.dart';
import 'package:tProject/scenes/searchpage.dart';
import 'package:tProject/styles/drawer.dart';
import 'package:tProject/helpers/helpermethodes.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../globals.dart';

class MainPage extends StatefulWidget {
  static const String id = "main";
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  Position currentPosition;
  bool drawerCanOpen = true;
  bool errorCodePromo = false;
  String error = " ";
  var fares;
  int i = 0;

  var tripDirectionDetails = null;
  var CodePromoController = TextEditingController();

  var rideRef;
  BitmapDescriptor nearbyIcon;

  bool nearbyDriversKeysLoaded = false;
  bool foundDriver = false;

  var promotionValue;

  var driver_token;

  NearByDriver driver;

  var showvalue = false;
  void updateDriversOnMap() {
    print('updating drivers on map');
    print(FireHelper.nearbyDriverList);
    setState(() {
      _markers.clear();
    });
    Set<Marker> tempMarkers = Set<Marker>();
    for (NearByDriver driver in FireHelper.nearbyDriverList) {
      LatLng driverPosition = LatLng(driver.latitude, driver.longitude);
      Marker thisMarker = Marker(
          markerId: MarkerId('driver${driver.key}'),
          position: driverPosition,
          icon: nearbyIcon,
          rotation: HelperMethods.generateRandomNumber(368));
      tempMarkers.add(thisMarker);
    }
    setState(() {
      _markers = tempMarkers;
    });
  }

  void startTimer() async {
    Timer _timer;
    int _start = 10;
    await new Timer(const Duration(seconds: 10), () => print(DateTime.now()));
  }

  void SendToNearbyDrivers() async {
    print('sending to  drivers');
    print(FireHelper.nearbyDriverList);
    DatabaseReference DriverRef;
   
    print('i ma here $i');
    setState(() {
      driver = FireHelper.nearbyDriverList.elementAt(i);
    });

    DatabaseReference token = await FirebaseDatabase.instance
        .reference()
        .child('drivers/${driver.key}')
        .once()
        .then((DataSnapshot snap) {
      print('la');
      print(snap.value['token']);
      setState(() {
        driver_token = snap.value['token'];
      });
    });

    var driverToken = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driver.key)
        .get()
        .then((snap) async {
      print('la');
      print(snap.data()['token']);
      setState(() {
        driver_token = snap.data()['token'];
      });

      await FirebaseDatabase.instance
          .reference()
          .child('drivers/${driver.key}/newtrip')
          .set(rideRef.key);

      FirebaseFirestore.instance
          .collection('drivers')
          .doc(driver.key)
          .update({'newtrip': rideRef.key});

      await Future.delayed(const Duration(seconds: 10));
      print('driver_token $driver_token');
      print('rideref ${rideRef.key}');
      HelperMethods.sendAndRetrieveMessage(driver_token, rideRef.key);
      print('sent messsage');
      //await startTimer();

      print('end timer');
      //sleep(new Duration(seconds: 10));
      //await Future.delayed(Duration(seconds: 10));
      print("end two");

      var driver_id = await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(rideRef.key);

      driver_id.get().then((value) {
        if (value.data()['driver_id'] != 'waiting')
          setState(() {
            foundDriver = true;
          });
      });

      /*
    var driver_id = await FirebaseDatabase.instance
        .reference()
        .child('riderRequest/${rideRef.key}');
    
    driver_id.once().then((DataSnapshot snapshot) {
      if (snapshot.value['driver_id'] != "waiting") {
        print(snapshot.value['driver_id']);
        setState(() {
          print('iam hereeeeee');
          foundDriver = true;
        });
      } else
        setState(() {
          //i = i + 1;
          print(i);
        });
    */
    });
  }

  void cancelRideRequest() {
    rideRef.remove();
    resetApp();
  }

  void checkCodePromo() async {
    // ignore: deprecated_member_use
    print('checking code promo ');
    var val;
    setState(() {
      fares = double.parse(
          HelperMethods.estimateFares(tripDirectionDetails).toString());
    });

    await FirebaseFirestore.instance
        .collection('CodesPromo')
        .where('code', isEqualTo: CodePromoController.text)
        .get()
        .then((QuerySnapshot value) {
      print('rrr $value');
      print(value.docs);
      if (value.docs.isEmpty == true) {
        setState(() {
          promotionValue = 0;
          errorCodePromo = true;
          error = "invalid";
          CodePromoController.text = "";
        });
      } else {
        Map documentFields = value.docs[0].data();

        setState(() {
          errorCodePromo = false;
          error = "";
          print(documentFields['promotion']);
          int y = int.parse(documentFields['promotion'].toString());
          print(y);
          promotionValue = (y / 100);
          print(promotionValue);
          var output = HelperMethods.estimateFares(tripDirectionDetails);
          print("zszszszszs $output");
          var va = double.parse(output.toString());
          print(va);

          fares = promotionValue * va;

          print('fares $fares');
          showRequestingSheet();
        });
      }
    });

    print('promotionValue $promotionValue');
    // rest of your code
  }

  void startGeoFireListener() {
    Geofire.initialize('driversAvailable');
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 100)
        .listen((map) {
      if (map != null) {
        var callBack = map['callBack'];
        print(map['callback']);
        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByDriver nearbyDriver = NearByDriver();
            nearbyDriver.key = map[' key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];
            print('adding');
            setState(() {
              int index = FireHelper.nearbyDriverList
                  .indexWhere((element) => element.key == driver.key);

              if (index < 0) FireHelper.nearbyDriverList.add(nearbyDriver);
            });

            print(FireHelper.nearbyDriverList);
            print(nearbyDriversKeysLoaded);
            if (nearbyDriversKeysLoaded) updateDriversOnMap();

            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            NearByDriver nearByDriver = NearByDriver();
            nearByDriver.key = map['key'];
            nearByDriver.latitude = map['latitude'];
            nearByDriver.longitude = map['longitude'];
            FireHelper.updateNearbyLocation(nearByDriver);
            updateDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            // All Intial Data is loaded

            setState(() {
              nearbyDriversKeysLoaded = true;
            });

            //FireHelper.nearbyDriverList = [];
            updateDriversOnMap();
            break;
        }
      }

      // setState(() {});
    });
  }

  void showDetailsSheet() async {
    await getDirection();
    setState(() {
      searchSheetHeight = 0;
      rideDetailsHeight = (Platform.isAndroid) ? 200 : 260;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = false;
    });
  }

  void showRequestingSheet() {
    print('showinnnggggg');
    setState(() {
      fares = double.parse(
          HelperMethods.estimateFares(tripDirectionDetails).toString());

      rideDetailsHeight = 0;
      requestingSheetHeight = (Platform.isAndroid) ? 195 : 220;
      drawerCanOpen = false;
    });

    createRideRequest();
  }

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration,
              (Platform.isIOS)
                  ? 'images/car_ios.png'
                  : 'images/car_android.png')
          .then((icon) => nearbyIcon = icon);
    }
  }

  void setupPoisitionLocator() async {
    print('hello world setting up position locator');
    Position currentposition = await GeolocatorPlatform.instance
        .getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);
    print('hey there');
    currentPosition = currentposition;
    print('zzaeazeaezezaeaze $currentPosition');
    LatLng pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 5);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    String address =
        await HelperMethods.findCoordinatesAddress(currentPosition, context);
    //FireHelper.nearbyDriverList = [];
    startGeoFireListener();
  }

  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double rideDetailsHeight = 0;

  double mapBottomPadding = 0;
  double searchSheetHeight = (Platform.isIOS) ? 300 : 195;
  double requestingSheetHeight = 0;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  Widget build(BuildContext context) {
    createMarker();
    return Scaffold(
      key: scaffoldkey,
      resizeToAvoidBottomInset: false,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: <Widget>[
              Container(
                color: Colors.white,
                height: 160,
                child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(children: <Widget>[
                      Image.asset(
                        "Images/user_icon.png",
                        height: 60,
                        width: 60,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('phone'),
                          SizedBox(
                            height: 5,
                          ),
                          FlatButton(
                            onPressed: () {},
                            child: Text('voir profile'),
                          )
                        ],
                      )
                    ])),
              ),
              SizedBox(
                height: 10,
              ),
              ListTile(
                  leading: Icon(Icons.card_giftcard),
                  title: Text('Mes Points', style: kDrawerItemStyle),
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyPoints()));
                  }),
              ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text('two', style: kDrawerItemStyle),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapBottomPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: _polylines,
            markers: _markers,
            circles: _circles,
            initialCameraPosition: kLake,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;

              setState(() {
                mapBottomPadding = (Platform.isAndroid) ? 200 : 270;
              });
              print('setting up position');
              setupPoisitionLocator();
            },
          ),

          // Menu button
          Positioned(
            top: 44,
            left: 20,
            child: GestureDetector(
              onTap: () {
                if (drawerCanOpen == true)
                  scaffoldkey.currentState.openDrawer();
                else
                  resetApp();
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    (drawerCanOpen) ? Icons.menu : Icons.arrow_back,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ),

          // Search Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.easeIn,
              duration: new Duration(milliseconds: 150),
              child: Container(
                height: searchSheetHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Ziouane Vite Vite',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text('votre Destination',
                          style: TextStyle(
                              fontSize: 18, fontFamily: 'Brand-Bold')),
                      SizedBox(height: 20),
                      //recherche
                      GestureDetector(
                        onTap: () async {
                          var response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchPAGE()));
                          if (response == 'getDirection') {
                            showDetailsSheet();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5.0,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7))
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.search, color: Colors.blueAccent),
                                SizedBox(
                                  width: 10,
                                ),
                                Text('Destination'),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          //Ride Price Details
          // searching  car request
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      color: Colors.black26,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                height: rideDetailsHeight,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text('Total'),
                                SizedBox(
                                  width: 16,
                                ),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text((tripDirectionDetails != null)
                                          ? tripDirectionDetails.distanceText
                                          : ''),
                                      Text('km')
                                    ]),
                                Expanded(
                                  child: Container(),
                                ),
                                Text(fares == null
                                    ? (tripDirectionDetails != null)
                                        ? HelperMethods.estimateFares(
                                            tripDirectionDetails)
                                        : ''
                                    : fares.toString()),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        currentUserInfo.entreprise != null
                            ? Row(
                                children: [
                                  Checkbox(
                                    checkColor: Colors.greenAccent,
                                    value: showvalue,
                                    onChanged: (bool value) {
                                      setState(() {
                                        showvalue = value;
                                        if (value == true)
                                          fares = 0;
                                        else
                                          checkCodePromo();
                                      });
                                    },
                                  ),
                                  Text('utiliser code entreprise')
                                ],
                              )
                            : Container(),
                        showvalue == false
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(children: <Widget>[
                                  TextField(
                                    controller: CodePromoController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                        labelText: 'Code ',
                                        errorStyle: TextStyle(),
                                        errorText: errorCodePromo == false
                                            ? ' '
                                            : error,
                                        labelStyle: TextStyle(fontSize: 14.0),
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        )),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ]),
                              )
                            : Container(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TaxiButton(
                                  title: 'valider',
                                  color: BrandColors.colorGreen,
                                  onPressed: () {
                                    if (CodePromoController.text != "") {
                                      checkCodePromo();
                                      if (errorCodePromo) {
                                        //showRequestingSheet();
                                        SendToNearbyDrivers();
                                      }
                                    } else {
                                      showRequestingSheet();
                                      SendToNearbyDrivers();
                                    }

                                    //print(promotionValue);
                                    /*
                                    if (CodePromoController.text != "") {
                                      var x = checkCodePromo();
                                      print(x);
                                      if (x != 0) {
                                        showRequestingSheet();
                                        SendToNearbyDrivers();
                                      } else {
                                        print(' je suis la ');
                                        setState(() {
                                          error = "invalid";
                                          errorCodePromo = true;
                                        });
                                      }
                                    } else {
                                      
                                      showRequestingSheet();
                                      SendToNearbyDrivers();
                                    }
                                  */
                                  },
                                ),
                                SizedBox(width: 30),
                                TaxiButton(
                                  title: 'Annuler',
                                  color: BrandColors.colorGreen,
                                  onPressed: () {
                                    resetApp();
                                  },
                                ),
                              ]),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // searhing car request
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(microseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                height: requestingSheetHeight,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 10,
                        ),
                        SafeArea(
                          child: Container(
                              child: foundDriver == false
                                  ? Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextLiquidFill(
                                            text: "Recherche...",
                                            waveColor:
                                                BrandColors.colorTextSemiLight,
                                            boxBackgroundColor: Colors.white,
                                            textStyle: TextStyle(
                                                color: BrandColors
                                                    .colorTextSemiLight,
                                                fontSize: 22.0,
                                                fontFamily: 'Brand-Bold'),
                                            boxHeight: 40,
                                          ),
                                        ),
                                        TaxiButton(
                                          color: Colors.red,
                                          title: 'Annuler',
                                          onPressed: () =>
                                              {cancelRideRequest()},
                                        )
                                      ],
                                    )
                                  : Container(
                                      width: double.infinity,
                                      color: Colors.white,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                  'Notre chauffeur va vous contacter'),
                                              TaxiButton(
                                                title: 'Valider',
                                                color: Colors.greenAccent,
                                                onPressed: () => {resetApp()},
                                              ),
                                            ],
                                          )),
                                    )),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                width: 1.0,
                                color: BrandColors.colorLightGrayFair),
                          ),
                        ),
                        TaxiButton(
                          title: 'Annuler',
                          color: Colors.greenAccent,
                          onPressed: () => {resetApp()},
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _polylines.clear();
      _markers.clear();
      _circles.clear();
      rideDetailsHeight = 0;
      searchSheetHeight = (Platform.isAndroid) ? 195 : 200;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = true;
      requestingSheetHeight = 0;
      //FireHelper.nearbyDriverList = [];
      setupPoisitionLocator();
    });
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;
    var pickLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);

    var pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: true);

    pr.style(
        message: 'Searching...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    //await pr.show();

    DirectionDetails thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetails = thisDetails;
    });

    print('detaaaiiilllsss');
    //print(thisDetails);

    //pr.hide();
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails.encodePoints);
    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      results.forEach((PointLatLng points) {
        polylineCoordinates.add(LatLng(points.latitude, points.longitude));
      });
      _polylines.clear();
      setState(() {
        Polyline line = Polyline(
            polylineId: PolylineId('polyid'),
            color: Color.fromARGB(255, 95, 109, 237),
            points: polylineCoordinates,
            jointType: JointType.round,
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true);
        _polylines.add(line);
      });

      // fit into map
      LatLngBounds bounds;
      if (pickLatLng.latitude > destinationLatLng.latitude &&
          pickLatLng.longitude > destinationLatLng.longitude)
        bounds =
            LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
      else if (pickLatLng.longitude > destinationLatLng.longitude)
        bounds = LatLngBounds(
            southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
            northeast:
                LatLng(destinationLatLng.latitude, pickLatLng.longitude));
      else if (pickLatLng.latitude > destinationLatLng.latitude)
        bounds = LatLngBounds(
            southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
            northeast:
                LatLng(pickLatLng.latitude, destinationLatLng.longitude));
      else
        bounds =
            LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);

      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      Marker pickupMarker = new Marker(
          markerId: MarkerId('pickup'),
          position: pickLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              InfoWindow(title: pickup.placeName, snippet: 'My Location'));
      Marker destinationMarker = new Marker(
          markerId: MarkerId('destination'),
          position: destinationLatLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow:
              InfoWindow(title: destination.placeName, snippet: 'Destination'));
      setState(() {
        _markers.add(pickupMarker);
        _markers.add(destinationMarker);
      });

      Circle pickupCircle = Circle(
          circleId: CircleId('pickup'),
          strokeColor: Colors.green,
          strokeWidth: 3,
          radius: 12,
          center: pickLatLng,
          fillColor: BrandColors.colorGreen);

      Circle destinationCircle = Circle(
          circleId: CircleId('destination'),
          strokeColor: BrandColors.colorAccentPurple,
          strokeWidth: 3,
          radius: 12,
          center: destinationLatLng,
          fillColor: BrandColors.colorAccentPurple);

      setState(() {
        _circles.add(pickupCircle);
        _circles.add(destinationCircle);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    HelperMethods.getCurrent(currentUserInfo);
  }

  void createRideRequest() async {
    print('i am here here create ride request');
    rideRef = FirebaseFirestore.instance.collection('rideRequests');
    print('rideref $rideRef');
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map pickupMap = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString(),
      'place': pickup.placeName
    };

    Map destinationMap = {
      'latitude': destination.latitude.toString(),
      'longitude': destination.longitude.toString(),
      'place': destination.placeName
    };

    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_phone': currentFirebaseUser.phoneNumber,
      'rider_id': currentFirebaseUser.uid,
      'pickup': pickupMap,
      'destination': destinationMap,
      'driver_id': 'waiting',
      'prix': fares
    };
  
    Map promotionMap = {'codePromo': '', 'promotion': ''};
    if (promotionValue != null) {
      promotionMap = {
        'codePromo': CodePromoController.text,
        'promotion': promotionValue,
      };
    }
    if (showvalue == true) {
      promotionMap = {
        'codePromo': CodePromoController.text,
        'promotion': promotionValue,
      };
    }
   
    print('i am rideMap');
    print(rideMap);

    await FirebaseFirestore.instance.collection('rideRequests').add({
      'created_at': DateTime.now().toString(),
      'rider_phone': currentFirebaseUser.phoneNumber,
      'rider_id': currentFirebaseUser.uid,
      'pickup': pickupMap,
      'destination': destinationMap,
      'driver_id': 'waiting',
      'prix': fares,
      'promotion':promotionMap
    }).then((value) => {
          setState(() {
            rideRef = value.id;
          })
        });
    
    //print(docRef);
    print('i am doc ref $rideRef');
    /* 
    rideRef = FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(docRef.toString())
        .get();

    */
  }
}
