import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: duplicate_import
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tProject/datamodels/address.dart';
import 'package:tProject/datamodels/datadetails.dart';
import 'package:tProject/datamodels/user.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/globals.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'requesthelper.dart';

class HelperMethods {
  static set currentUserInfo(currentUserInfo) {}

  static void getCurrent(currentUserInfo) async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser;
    Userx ikram = new Userx();
    String userid = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');
    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        ikram.id = snapshot.key;
        ikram.phone = snapshot.value['phone'];

        currentUserInfo.id = snapshot.key;
        currentUserInfo.phone = snapshot.value['phone'];

        print(snapshot.value['entreprise']);
        if (snapshot.value['entreprise'] != null) {
          currentUserInfo.entreprise = snapshot.value['entreprise'];
        }
        if (snapshot.value['earnings'] != null) {
          currentUserInfo.earnings = snapshot.value['earnings'];
        }
      }
    });
    print('current user ${currentUserInfo.entreprise}');
  }

  static double generateRandomNumber(int max) {
    var randomGenerator = Random();
    int randInt = randomGenerator.nextInt(max);

    return randInt.toDouble();
  }

  static Future<Map<String, dynamic>> sendAndRetrieveMessage(
      userid, rideid) async {
    print('iam userid $userid');
    print('iam ride id $rideid');

    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=${serverToken}',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'this is a body',
            'title': 'this is a title'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            'ride_id': rideid,
          },
          'to': userid,
        },
      ),
    );

    final Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        completer.complete(message);
      },
    );

    return completer.future;
  }

  static Future<String> findCoordinatesAddress(
      Position position, context) async {
    String placeAddress = "";
    print('finding coords ');
    print(position.latitude);
    print(position.longitude);
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey";

    var response = await RequestHelper.getRequest(url);
    print(response);
    if (response != 'failed') {
      placeAddress = response['results'][0]['formatted_address'];
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
    print(startPosition);
    print(endPosition);
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=driving&key=${mapkey}";
    var response = await RequestHelper.getRequest(url);
    print(response['routes']);
    print("res $response");
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
    //print(details.distanceText);
    //print(details.distanceValue);
    double distanceFare = (details.distanceValue / 1000) * 50;
    //duree en minutes
    // ignore: unused_local_variable
    double timeFare = (details.distanceValue / 60);

    return distanceFare.toString();
  }
}
