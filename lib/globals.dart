import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'datamodels/user.dart';

String mapkey = "AIzaSyAYMGtiSSQXoEzYruYwej05H3hsHRHlmRc";

final CameraPosition kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 5);
//19.151926040649414);

User currentFirebaseUser;
Userx currentUserInfo = new Userx();

String entreprise;

final String serverToken =
    'AAAAmU5n7PA:APA91bFEalSyM0RBT0uTlYfD7NwMn0CWaNMjJeGfYhJ8LD9rt5CvdWkkASAn_O1AkjKY_0ItzcdbTjB9Fix17oFWKAi0p-XPfHpebTKKwJQ643UAUL0kft6i7pbOWuRuNkluU8F2XROW';
final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
List Entreprises = [];
List Entreprises_names = [];
