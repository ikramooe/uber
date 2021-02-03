import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ff_contact_avatar/ff_contact_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:tProject/scenes/historypage.dart';
import 'package:tProject/scenes/points.dart';
import 'package:tProject/scenes/profile.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/scenes/searchpage.dart';
import 'package:tProject/scenes/support.dart';
import 'package:tProject/styles/drawer.dart';
import 'package:tProject/helpers/helpermethodes.dart';
import 'package:tProject/widgets/collectpaiement.dart';
import 'package:tProject/widgets/nodriver.dart';
import 'package:tProject/widgets/rating.dart';
import 'package:tProject/widgets/taxibutton.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
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

  var driver_id;

  bool companyIsActive = false;

  void showToast(String msg, {int duration, int gravity}) {
    Toast.show(msg, context, duration: duration, gravity: gravity);
  }

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
  var id;

  var driver_name;

  var driver_prenom;
  var status;
  String tripStatusDisplay = "hello";

  int driverRequestTimeout = 30;
  void _launchCaller() async {
    var url = "tel:${diver_phone}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void checkifEntrepriseActive() async {
    print(currentUserInfo.entreprise);
    await FirebaseFirestore.instance
        .collection('Companies')
        .where('code', isEqualTo: currentUserInfo.entreprise)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        print(querySnapshot.docs);
        print(querySnapshot.docs[0]);
        companyIsActive = querySnapshot.docs[0].data()['status'] != "Suspended";
      });
    });
  }

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
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driver.key)
        .get()
        .then((snap) async {
      setState(() {
        driver_token = snap.data()['token'];
      });
    });

    var driverTripRef =
        await FirebaseFirestore.instance.collection('drivers').doc(driver.key);

    await driverTripRef.update({'newtrip': rideRef});
    // send notification to selected driver
    await HelperMethods.sendAndRetrieveMessage(driver_token, rideRef);
    const oneSecTick = Duration(seconds: 1);
    Timer.periodic(oneSecTick, (timer) {
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

        if (event.data()['newtrip'] == 'declined') {
          listener.cancel();
          timer.cancel();
          driverRequestTimeout = 0;
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

  String greeting() {
    var hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Bonjour';
    }
    if (hour >= 12 && hour < 17) {
      return 'Bonne après-midi';
    }
    if (hour >= 17) {
      return 'Bonsoir';
    }
  }

  void startGeoFireListener() {
    Geofire.initialize('driversAvailable');
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 100)
        .listen((map) {
      if (map != null) {
        var callBack = map['callBack'];
        print('maaaaaapppppp----------------------------');

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByDriver nearbyDriver = NearByDriver();
            print('i aaaaam hereeee');
            print(map);
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];
            nearbyDriver.distance = distanceBetween(
                currentPosition.latitude,
                currentPosition.longitude,
                nearbyDriver.latitude,
                nearbyDriver.longitude);

            print('adding');
            setState(() {
              int index = FireHelper.nearbyDriverList
                  .indexWhere((element) => element.key == driver.key);
              if (index < 0) {
                FireHelper.nearbyDriverList.add(nearbyDriver);
                FireHelper.nearbyDriverList
                    .sort((a, b) => a.distance.compareTo(b.distance));
              }
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
            nearByDriver.distance = distanceBetween(
                currentPosition.latitude,
                currentPosition.longitude,
                nearByDriver.latitude,
                nearByDriver.longitude);

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
    if (currentUserInfo.entreprise != "AUCUNE" &&
        currentUserInfo.entreprise != "") await checkifEntrepriseActive();
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
  double searchSheetHeight = (Platform.isIOS) ? 300 : 170;
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
        //key: scaffoldkey,
        width: 250,
        color: BrandColors.colorGrey,
        child: Container(
          color: BrandColors.colorGrey,
          child: Drawer(
            child: Container(
              color: BrandColors.colorGrey,
              child: ListView(
                padding: EdgeInsets.all(0),
                children: <Widget>[
                  Container(
                    height: 140,
                    child: Container(
                      decoration: BoxDecoration(
                        color: BrandColors.colorOrangeclair,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: FFContactAvatar(
                          name: (currentUserInfo.nom != null &&
                                  currentUserInfo.prenom != null)
                              ? '${currentUserInfo.nom} ${currentUserInfo.prenom}'
                              : 'Bienvenu',
                          message: '',
                          showBadge: false,
                        ),
                      ),
                    ),

                    /*
                          Image.asset(
                            "images/user_icon.png",
                            height: 45,
                            width: 60,
                          ),
                          */
                    /*
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FlatButton(
                                onPressed: () {},
                                child: Text(
                                  (currentUserInfo.nom != null &&
                                          currentUserInfo.prenom != null)
                                      ? '${currentUserInfo.nom} ${currentUserInfo.prenom}'
                                      : 'Bienvenu',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'Brand-Bold'),
                                ),
                              )
                            ],
                          )
                          */
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ListTile(
                      leading: Icon(Icons.person, color: Colors.white),
                      title: Text('Profile', style: kDrawerItemStyle),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfilePage()));
                      }),
                  ListTile(
                      leading: Icon(Icons.card_giftcard, color: Colors.white),
                      title: Text('Mes Points', style: kDrawerItemStyle),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyPoints()));
                      }),
                  ListTile(
                      leading: Icon(Icons.history, color: Colors.white),
                      title: Text('Historique', style: kDrawerItemStyle),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HistoryPage()));
                      }),
                  ListTile(
                      leading: Icon(Icons.headset, color: Colors.white),
                      title: Text('Support', style: kDrawerItemStyle),
                      onTap: () async {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Support()));
                      }),
                  ListTile(
                      leading: Icon(Icons.all_out, color: Colors.white),
                      title: Text('Deconnecter', style: kDrawerItemStyle),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()));
                      }),
                ],
              ),
            ),
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
                    color: BrandColors.colorGrey,
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
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      Text(
                          currentUserInfo.nom != null &&
                                  currentUserInfo.prenom != null
                              ? '${greeting()} ${currentUserInfo.nom} ${currentUserInfo.prenom} '
                              : 'Bienvenu',
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Brand-Bold',
                              color: Colors.white)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset('images/pickicon.png',
                              height: 16, width: 16),
                          SizedBox(
                            width: 18,
                          ),
                          Text(
                              Provider.of<AppData>(context).pickupAddress !=
                                      null
                                  ? Provider.of<AppData>(context)
                                      .pickupAddress
                                      .placeName
                                  : 'localisation en cours ...',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Brand-Bold',
                                  color: Colors.white)),
                        ],
                      ),

                      //recherche
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (Provider.of<AppData>(context, listen: false)
                                  .pickupAddress !=
                              null) {
                            var response = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchPAGE()));
                            if (response == 'getDirection') {
                              showDetailsSheet();
                            }
                          } else
                            showToast('en cours de localisation');
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
                                Icon(Icons.search,
                                    color: BrandColors.colorOrangeclair),
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
                  color: BrandColors.colorGrey,
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: BrandColors.colorGrey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          fares == null
                                              ? (tripDirectionDetails != null)
                                                  ? HelperMethods.estimateFares(
                                                          tripDirectionDetails) +
                                                      ' DZD'
                                                  : ''
                                              : fares.toString() + 'DZD',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ]),
                                Expanded(
                                  child: Container(),
                                ),
                                Text('Distance',
                                    style: TextStyle(color: Colors.white)),
                                SizedBox(width: 2),
                                Text(
                                    (tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : '',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        (companyIsActive == true)
                            ? Row(
                                children: [
                                  Checkbox(
                                    checkColor: Colors.green,
                                    value: showvalue,
                                    onChanged: (bool value) {
                                      setState(() {
                                        showvalue = value;
                                        if (value == true) {
                                          rideDetailsHeight = 125;
                                          fares = 0;
                                        } else {
                                          rideDetailsHeight = 200;
                                          checkCodePromo();
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'utiliser code entreprise ${currentUserInfo.entreprise}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(height: 20),
                        showvalue == false
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Theme(
                                  data: new ThemeData(
                                    primaryColor: Colors.white,
                                    primaryColorDark: Colors.white,
                                  ),
                                  child: TextField(
                                    controller: CodePromoController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            bottom: -5, left: 6),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide(
                                                color: Colors.white)),
                                        labelText: 'Code Promo',
                                        errorStyle:
                                            TextStyle(color: Colors.white),
                                        errorText: errorCodePromo == false
                                            ? ' '
                                            : error,
                                        labelStyle: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.white),
                                        hintStyle: TextStyle(
                                          color: Colors.white,
                                        )),
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            : Container(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TaxiButton(
                                  textcol: Colors.black,
                                  title: 'Annuler',
                                  color: Colors.white,
                                  onPressed: () {
                                    resetApp();
                                  },
                                ),
                                SizedBox(width: 30),
                                TaxiButton(
                                  title: 'Valider',
                                  color: BrandColors.colorOrangeclair,
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
                                  text: 'Recherche de Chauffeur...',
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
                                  'Annuler',
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
                        Row(
                          children: [
                            Text(
                              driver_prenom != null
                                  ? driver_prenom
                                  : 'Chauffeur',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 20),
                            Text(
                              driver_name != null
                                  ? driver_name
                                  : 'Ziouane ViteVite',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
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
                                  child: FlatButton(
                                      onPressed: () {
                                        _launchCaller();
                                      },
                                      child: Icon(Icons.call)),
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
                                Text('Annuler'),
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
      searchSheetHeight = (Platform.isAndroid) ? 170 : 170;
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

    tripDirectionDetails = thisDetails;

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
    print(currentUserInfo.entreprise);
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
    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_phone': currentFirebaseUser.phoneNumber,
      'rider_id': currentFirebaseUser.uid,
      'pickup': pickupMap,
      'destination': destinationMap,
      'driver_id': 'waiting',
      'prix': fares,
      'promotion': promotionMap
    };
    currentUserInfo.trips.add(rideMap);

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
            rideRef = value.id;
            rideId = value.id;
            print('i am ride ref $rideRef');
          })
        });

    DocumentReference reference = await FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(rideRef);

    reference.snapshots().listen((querySnapshot) async {
      if (querySnapshot.data()['status'] == 'accepted') {
        await setState(() {
          print(querySnapshot.data());
          diver_phone = querySnapshot.data()['driver_phone'];
          driver_name = querySnapshot.data()['driver_name'];
          driver_prenom = querySnapshot.data()['driver_prenom'];
          id = querySnapshot.data()['id'];
          status = querySnapshot.data()['status'];
          print('i am current user info ${currentUserInfo.trips}');
          print('i am current user info ${currentUserInfo.trips.length}');
          currentUserInfo.trips[currentUserInfo.trips.length - 1]
              ['driver_phone'] = diver_phone;
          currentUserInfo.trips[currentUserInfo.trips.length - 1]
              ['driver_name'] = driver_name;
          currentUserInfo.trips[currentUserInfo.trips.length - 1]
              ['driver_prenom'] = driver_prenom;
          currentUserInfo.trips[currentUserInfo.trips.length - 1]
              ['requestRef'] = rideRef;
          currentUserInfo.trips[currentUserInfo.trips.length - 1]['id'] = id;
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentFirebaseUser.uid)
              .update({'trips': currentUserInfo.trips});
        });
      }
      print('i am driver_name $driver_name');
      //get driver location updates
      if (querySnapshot.data()['driver_location'] != null) {
        print('here driver_location');
        double driverLat = double.parse(
            querySnapshot.data()['driver_location']['latitude'].toString());
        double driverLng = double.parse(
            querySnapshot.data()['driver_location']['longitude'].toString());
        LatLng driverLocation = LatLng(driverLat, driverLng);

        if (querySnapshot.data()['status'] == 'accepted') {
          await updateToPickup(driverLocation);
        } else if (querySnapshot.data()['status'] == 'ontrip') {
          await updateToDestination(driverLocation);
        } else if (querySnapshot.data()['status'] == 'arrived') {
          await setState(() {
            tripStatusDisplay = 'Driver has arrived';
          });
        }
      }

      if (querySnapshot.data()['status'] == 'accepted') {
        print('i am here stopping geofire listener');
        showTripSheet();
        //Geofire.stopListener();
        //removeGeofireMarkers();
      }

      if (querySnapshot.data()['status'] == 'ended') {
        if (querySnapshot.data()['prix'] != null) {
          String fares = querySnapshot.data()['prix'].toString();

          var response = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectPayment(
              paymentMethod: 'cash',
              fares: fares,
            ),
          );

          if (response == 'close') {
            var response2 = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => Rating(ref: rideRef),
            );
            if (response2 == 'close') resetApp();
          }
        }
      }
    });
    // Do something with change

    availableDrivers = FireHelper.nearbyDriverList;
    //reversing list
    availableDrivers = availableDrivers.reversed.toList();
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
    setState(() {
      availableDrivers.removeAt(0);
      print('');
      print(availableDrivers.length);
    });

    print('i am here drivers available');
    print(availableDrivers);
  }

  void removeGeofireMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.contains('driver'));
    });
  }

  void updateToPickup(LatLng driverLocation) async {
    print('i am here updating to pickup');

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
