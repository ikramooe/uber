import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/scenes/searchpage.dart';
import 'package:tProject/styles/drawer.dart';
import 'package:tProject/helpers/helpermethodes.dart';

class MainPage extends StatefulWidget {
  static const String id = "main";
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  //Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;
  Position currentPosition;

  void setupPoisitionLocator() async {
    //Position position = await getCurrentPosition()
    print('hey ');
    currentPosition =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    String address =
        await HelperMethods.findCoordinatesAddress(currentPosition, context);
    //print("meeeeeeeeeeeeeeeeeee");
    //print(address);
  }

  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;

  double mapBottomPadding = 0;
  double searchSheetHeight = (Platform.isIOS) ? 300 : 0;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldkey,
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
            initialCameraPosition: _kLake,
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
                scaffoldkey.currentState.openDrawer();
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
                    Icons.menu,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ),

          // Search
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200,
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
                    Text('Ziouane Vite Vite', style: TextStyle(fontSize: 10)),
                    Text('rerre',
                        style:
                            TextStyle(fontSize: 18, fontFamily: 'Brand-Bold')),
                    SizedBox(height: 20),
                    //recherche
                    GestureDetector(
                      onTap: () async {
                        var response = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchPAGE()));
                        if (response == 'getDirection') {
                          await getDirection();
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
          )
        ],
      ),
    );
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

    await pr.show();

    var thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);

    pr.hide();
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
    }
  }
}
