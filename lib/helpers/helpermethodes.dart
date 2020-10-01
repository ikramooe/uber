import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: duplicate_import
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tProject/datamodels/address.dart';
import 'package:tProject/datamodels/datadetails.dart';
import 'package:tProject/datamodels/user.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/globals.dart';
import 'package:geolocator/geolocator.dart';

import 'requesthelper.dart';

class HelperMethods {
  static set currentUserInfo(currentUserInfo) {}

  static void getCurrent() async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser;
    Userx ikram = new Userx();
    String userid = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');
    userRef.once().then((DataSnapshot snapshot) => {
          if (snapshot.value != null)
            {
              
              

              ikram.id = snapshot.key,
              ikram.phone = snapshot.value['phone'],
              currentUserInfo  = ikram,
              
              
            }
        });
  }

  static Future<String> findCoordinatesAddress(
      Position position, context) async {
    String placeAddress = "";

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey";

    var response = await RequestHelper.getRequest(url);
    //print(response);
    if (response != 'failed') {
      placeAddress = response['results'][0]['formatted_address'];
      //print(placeAddress);
      Address pickupAddress = new Address();
      pickupAddress.longitude = position.longitude;
      pickupAddress.latitude = position.latitude;
      pickupAddress.placeFormattedAddress = placeAddress;
      pickupAddress.placeName = placeAddress;
      Provider.of<AppData>(context, listen: false)
          .updatePickUpAddress(pickupAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> getDirectionDetails(
      LatLng startPosition, LatLng endPosition) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=driving&key=${mapkey}";
    var response = await RequestHelper.getRequest(url);
    //print(response['routes']['duration']['text']);

    DirectionDetails directionDetails = new DirectionDetails();

    directionDetails.durationText =
        response['routes'][0]['legs'][0]['duration']['text'];
    directionDetails.durationValue =
        response['routes'][0]['legs'][0]['duration']['value'];
    directionDetails.distanceText =
        response['routes'][0]['legs'][0]['distance']['text'];

    directionDetails.distanceValue =
        response['routes'][0]['legs'][0]['distance']['value'];

    directionDetails.encodePoints =
        response['routes'][0]['overview_polyline']['points'];

    return directionDetails;
  }

  static String estimateFares(DirectionDetails details) {
    // per kilo 50 dzd
    //per minute
    //convertir en km

    print(details.distanceText);
    print(details.distanceValue);
    double distanceFare = (details.distanceValue / 1000) * 50;
    //duree en minutes
    // ignore: unused_local_variable
    double timeFare = (details.distanceValue / 60);
    return distanceFare.toString();
  }
}
