import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:tProject/scenes/mainpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    name: 'db2',
    options: Platform.isIOS || Platform.isMacOS
        ? FirebaseOptions(
            appId: '1:63435892294:ios:542adb50a6ba2a48014c47',
            apiKey: 'AIzaSyDiK4b4xLVPLlKTccBnwEupZXd_St6BsHM',
            projectId: 'flutter-firebase-plugins',
            messagingSenderId: '63435892294',
            databaseURL: 'https://uber-87da6.firebaseio.com',
          )
        : FirebaseOptions(
            appId: '1:63435892294:android:db60ae9e2d0cffa7014c47R',
            apiKey: 'AIzaSyDDLHw4nf5GdGAUCcYHDuZVMQb5ERvS-Mw',
            messagingSenderId: '297855924061',
            projectId: 'flutter-firebase-plugins',
            databaseURL: 'https://uber-87da6.firebaseio.com',
          ),
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
     home:MainPage()
   );
  }
}
