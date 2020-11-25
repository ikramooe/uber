import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:tProject/helpers/referralhelper.dart';
import 'package:tProject/scenes/points.dart';
import 'package:tProject/scenes/profile.dart';
import 'package:tProject/scenes/searchpage.dart';
import 'package:tProject/styles/drawer.dart';
import 'package:tProject/helpers/helpermethodes.dart';
import 'package:tProject/widgets/collectpaiement.dart';
import 'package:tProject/widgets/nodriver.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../globals.dart';

class MainPage extends StatefulWidget {
  static const String id = "main";
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  List availableDrivers = [];
  Position currentPosition;
  bool drawerCanOpen = true;
  bool errorCodePromo = false;
  String error = " ";
  String rideId;
  var listener;
  var fares;
  int i = 0;
  bool isRequestingLocationDetails = false;
  String appState = 'NORMAL';
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

  var diver_phone;

  var driver_name;

  var driver_prenom;
  var status;
  String tripStatusDisplay = "hello";

  int driverRequestTimeout = 30;
  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverDialog());
  }

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
    await new Timer(const Duration(seconds: 10), () => print(DateTime.now()));
  }

  void notifyDriver(NearByDriver driver) async {
    print('i am rideref');
    print(rideRef);
    //var driver_token;
    var driverToken = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driver.key)
        .get()
        .then((snap) async {
      setState(() {
        driver_token = snap.data()['token'];
      });
    });
    print('heeeeeeeerrreeeeeee------${driver_token}');
    var driverTripRef =
        await FirebaseFirestore.instance.collection('drivers').doc(driver.key);

    await driverTripRef.update({'newtrip': rideRef});
    // send notification to selected driver
    await HelperMethods.sendAndRetrieveMessage(driver_token, rideRef);
    const oneSecTick = Duration(seconds: 1);
    var timer = Timer.periodic(oneSecTick, (timer) {
      // stop timer when ride request is cancelled;
      if (appState != 'REQUESTING') {
        driverTripRef.update({'newtrip': 'cancelled'});
        timer.cancel();
        driverRequestTimeout = 30;
        if (listener != null) listener.cancel();
      }
      driverRequestTimeout--;
      listener = driverTripRef.snapshots().listen((event) async {
        if (event.data()['newtrip'] == 'accepted') {
          listener.cancel();
          timer.cancel();
          driverRequestTimeout = 30;
        }
      });
      if (driverRequestTimeout == 0) {
        //informs driver that ride has timed out
        driverTripRef.update({'newtrip': 'timeout'});
        listener.cancel();
        driverRequestTimeout = 30;
        timer.cancel();
        //select the next closest driver
        findDriver();
      }
    });
  }

  void informTimedOut(driver_id) {
    driver_id.get().update({'newtrip': 'timedout'});
  }

  void SendToNearbyDrivers(rideRef) async {
    print('sending to driver');
    print('i am rideref $rideRef');
    if (FireHelper.nearbyDriverList.length == 0) {
      cancelRideRequest();
      noDriverFound();
      return;
    } else {
      driver = FireHelper.nearbyDriverList.removeAt(0);
      notifyDriver(driver);
      await Future.delayed(const Duration(seconds: 10));

      var driver_id = await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(rideRef);

      await driver_id.get().then((value) {
        if (value.data()['driver_id'] != 'waiting')
          setState(() {
            foundDriver = true;
          });
      });

      if (!foundDriver) {
        informTimedOut(driver_id);
        SendToNearbyDrivers(rideRef);
      }
    }
  }

  void cancelRideRequest() {
    FirebaseFirestore.instance.collection('rideRequests').doc(rideId).delete();
    setState(() {
      appState = 'NORMAL';
    });
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
          int y = int.parse(documentFields['promotion'].toString());
          print(y);
          promotionValue = (y / 100);
          print(promotionValue);
          var output = HelperMethods.estimateFares(tripDirectionDetails);
          var va = double.parse(output.toString());
          fares = promotionValue * va;
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
        print('maaaaaapppppp----------------------------');
        print(map['callback']);
        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByDriver nearbyDriver = NearByDriver();
            nearbyDriver.key = map['key'];
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
            print('maaaaaaappppppppp ${map['key']}');
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

  showTripSheet() {
    setState(() {
      requestingSheetHeight = 0;
      tripSheetHeight = (Platform.isAndroid) ? 200 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
    });
  }

  Future<void> showRequestingSheet() async {
    setState(() {
      fares = double.parse(
          HelperMethods.estimateFares(tripDirectionDetails).toString());
      rideDetailsHeight = 0;
      requestingSheetHeight = (Platform.isAndroid) ? 195 : 220;
      drawerCanOpen = false;
    });

    await createRideRequest();
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
    Position currentposition = await GeolocatorPlatform.instance
        .getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);

    currentPosition = currentposition;

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
  double tripSheetHeight = 0;

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
                        "images/user_icon.png",
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
                  leading: Icon(Icons.person),
                  title: Text('Profile', style: kDrawerItemStyle),
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ProfilePage()));
                  }),
              ListTile(
                  leading: Icon(Icons.card_giftcard),
                  title: Text('Mes Points', style: kDrawerItemStyle),
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyPoints()));
                  }),
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
                        (currentUserInfo.entreprise != null &&
                                currentUserInfo.entreprise != "")
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
                                  Text(
                                      'utiliser code entreprise ${currentUserInfo.entreprise}')
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
                                  onPressed: () async {
                                    if (CodePromoController.text != "") {
                                      checkCodePromo();
                                      if (errorCodePromo) {
                                        //showRequestingSheet();
                                        //SendToNearbyDrivers();
                                      }
                                    } else {
                                      setState(() {
                                        appState = 'REQUESTING';
                                      });
                                      showRequestingSheet();
                                                                            //SendToNearbyDrivers();
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
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: TextLiquidFill(
                                  text: 'Requesting a Ride...',
                                  waveColor: BrandColors.colorTextSemiLight,
                                  boxBackgroundColor: Colors.white,
                                  textStyle: TextStyle(
                                      color: BrandColors.colorText,
                                      fontSize: 22.0,
                                      fontFamily: 'Brand-Bold'),
                                  boxHeight: 40.0,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  cancelRideRequest();
                                },
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        width: 1.0,
                                        color: BrandColors.colorLightGrayFair),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: double.infinity,
                                child: Text(
                                  'Cancel ride',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
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
          ),
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
                      color: Colors.black26,
                      blurRadius: 15.0, // soften the shadow
                      spreadRadius: 0.5, //extend the shadow
                      offset: Offset(
                        0.7, // Move to right 10  horizontally
                        0.7, // Move to bottom 10 Vertically
                      ),
                    )
                  ],
                ),
                height: tripSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 5,
                        ),
                        
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tripStatusDisplay,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, fontFamily: 'Brand-Bold'),
                              ),
                            ],
                          ),
                        
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          driver_prenom != null ? driver_prenom : 't',
                          style: TextStyle(color: BrandColors.colorTextLight),
                        ),
                        Text(
                          driver_name != null ? driver_name : 'e',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular((25))),
                                    border: Border.all(
                                        width: 1.0,
                                        color: BrandColors.colorTextLight),
                                  ),
                                  child: Icon(Icons.call),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Call'),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular((25))),
                                    border: Border.all(
                                        width: 1.0,
                                        color: BrandColors.colorTextLight),
                                  ),
                                  child: Icon(Icons.list),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text('Details'),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular((25))),
                                    border: Border.all(
                                        width: 1.0,
                                        color: BrandColors.colorTextLight),
                                  ),
                                  child: Icon(Icons.clear),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text('Cancel'),
                              ],
                            ),
                          ],
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
      tripSheetHeight = 0;
      rideDetailsHeight = 0;
      searchSheetHeight = (Platform.isAndroid) ? 195 : 200;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = true;
      tripStatusDisplay = 'Driver is Arriving';

      requestingSheetHeight = 0;
      //FireHelper.nearbyDriverList = [];
      status = "";
      driver_name = "";
      diver_phone = "";
    });
    setupPoisitionLocator();
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
    HelperMethods.getCurrent();
    print('getting current user info ');
    print(currentUserInfo.entreprise != null);
    print(currentUserInfo.entreprise != "");
    ReferralHelper.initDynamicLinks();
    ReferralHelper.initialize();
    ReferralHelper.createLink();
  }

  void createRideRequest() async {
    var x = FirebaseFirestore.instance.collection('rideRequests');
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

    await FirebaseFirestore.instance.collection('rideRequests').add({
      'status': 'waiting',
      'created_at': DateTime.now().toString(),
      'rider_phone': currentFirebaseUser.phoneNumber,
      'rider_id': currentFirebaseUser.uid,
      'pickup': pickupMap,
      'destination': destinationMap,
      'driver_id': 'waiting',
      'prix': fares,
      'promotion': promotionMap,
    }).then((value) => {
          setState(() {
            print('heeeeereeeeeeeeee-----------');
            print(value.id);
            rideRef = value.id;
            rideId = value.id;
            print('i am ride ref $rideRef');
          })
        });

    
    DocumentReference reference = await FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(rideRef);

    reference.snapshots().listen((querySnapshot) async {
      if (querySnapshot.data()['status'] != 'waiting') {
        print('i am here not waiting ');
        await setState(() {
          diver_phone = querySnapshot.data()['driver_phone'];
          driver_name = querySnapshot.data()['driver_nom'];
          driver_prenom = querySnapshot.data()['driver_prenom'];
          status = querySnapshot.data()['status'];
        });
      }
      print('i am driver_name $driver_name');
      //get driver location updates
      if (querySnapshot.data()['driver_location'] != null) {
        double driverLat = double.parse(
            querySnapshot.data()['driver_location']['latitude'].toString());
        double driverLng = double.parse(
            querySnapshot.data()['driver_location']['longitude'].toString());
        LatLng driverLocation = LatLng(driverLat, driverLng);

        if (status == 'accepted') {
          await updateToPickup(driverLocation);
        } else if (status == 'ontrip') {
         await updateToDestination(driverLocation);
        } else if (status == 'arrived') {
          await setState(() {
            tripStatusDisplay = 'Driver has arrived';
          });
        }
      }

      if (status == 'accepted') {
        showTripSheet();
        Geofire.stopListener();
        removeGeofireMarkers();
      }

      if (status == 'ended') {
        if (querySnapshot.data()['prix'] != null) {
          int fares = int.parse(querySnapshot.data()['fares'].toString());

          var response = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectPayment(
              paymentMethod: 'cash',
              fares: fares,
            ),
          );

          if (response == 'close') {
            //rideRef.onDisconnect();
            //rideRef = null;
            
            
            

            resetApp();
          }
        }
      }
    });
    // Do something with change
    print('here is ride reeeeefff $rideRef');
    availableDrivers =FireHelper.nearbyDriverList;
    findDriver();
  }

  void findDriver() {
    print('i am here finding driver');
    if (availableDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers[0];
    print('entering notify driver');
    notifyDriver(driver);

    availableDrivers.removeAt(0);

    print(driver.key);
  }

  void removeGeofireMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.contains('driver'));
    });
  }

  void updateToPickup(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var positionLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, positionLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        tripStatusDisplay = 'Driver is Arriving - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }

  void updateToDestination(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var destination =
          Provider.of<AppData>(context, listen: false).destinationAddress;

      var destinationLatLng =
          LatLng(destination.latitude, destination.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, destinationLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            'Driving to Destination - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }
}
