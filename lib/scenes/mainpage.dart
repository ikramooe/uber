import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
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

  var tripDirectionDetails = null;

  DatabaseReference rideRef;
  BitmapDescriptor nearbyIcon;

  bool nearbyDriversKeysLoaded;

  void updateDriversOnMap() {
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

  void startGeoFireListener() {
    Geofire.initialize('driversAvailible');
    // 5 kilometers
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 5)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByDriver nearbyDriver = NearByDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];
            FireHelper.nearbyDriverList.add(nearbyDriver);

            if (nearbyDriversKeysLoaded) {
              updateDriversOnMap();
            }
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
            nearbyDriversKeysLoaded = true;
            updateDriversOnMap();
            break;
        }
      }

      setState(() {});
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
    setState(() {
      rideDetailsHeight = 0;
      requestingSheetHeight = (Platform.isAndroid) ? 195 : 220;
      drawerCanOpen = false;
    });
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
    //Position position = await getCurrentPosition()

    currentPosition =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 5);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    String address =
        await HelperMethods.findCoordinatesAddress(currentPosition, context);
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
              ),
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
              //
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Text('Total'),
                              SizedBox(
                                width: 16,
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : ''),
                                    Text('km')
                                  ]),
                              Expanded(
                                child: Container(),
                              ),
                              Text((tripDirectionDetails != null)
                                  ? HelperMethods.estimateFares(
                                      tripDirectionDetails)
                                  : ''),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TaxiButton(
                          title: 'valider',
                          color: BrandColors.colorGreen,
                          onPressed: () {
                            showRequestingSheet();
                          },
                        ),
                      )
                    ],
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
                          child: SizedBox(
                            width: double.infinity,
                            child: TextLiquidFill(
                              text: "Recherche...",
                              waveColor: BrandColors.colorTextSemiLight,
                              boxBackgroundColor: Colors.white,
                              textStyle: TextStyle(
                                  color: BrandColors.colorTextSemiLight,
                                  fontSize: 22.0,
                                  fontFamily: 'Brand-Bold'),
                              boxHeight: 40,
                            ),
                          ),
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
                        onPressed: () => {},
                      )
                    ],
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
    HelperMethods.getCurrent();
  }

  void createRideRequest() {
    rideRef =
        FirebaseDatabase.instance.reference().child('riderRequest').push();
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
      'rider_phone': currentUserInfo.phone,
      'rider_id': currentUserInfo.id,
      'pickup': pickupMap,
      'destination': destinationMap,
      'driver_id': 'waiting'
    };
    rideRef.set(rideMap);
  }
}
