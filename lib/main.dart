import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:tProject/scenes/mainpage.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/scenes/riderphone.dart';
import 'package:tProject/scenes/riderregister.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    name: 'db2',
    options: Platform.isIOS || Platform.isMacOS
        ? FirebaseOptions(
            appId: '1:658445430000:ios:42ffd961aee52cbc69e635',
            apiKey: 'AIzaSyCUSemoprJW5qYL2YCDlVJbjHHj9qBHMyQ',
            projectId: 'ziouan-vite-vite',
            messagingSenderId: '658445430000',
            databaseURL: 'https://ziouan-vite-vite.firebaseio.com',
          )
        : FirebaseOptions(
            appId: '1:658445430000:android:0e42bdd1f974e92769e635',
            apiKey: 'AIzaSyAYMGtiSSQXoEzYruYwej05H3hsHRHlmRc',
            messagingSenderId: '658445430000',
            projectId: 'ziouan-vite-vite',
            databaseURL: 'https://ziouan-vite-vite.firebaseio.com',
          ),
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Brand-Regular'
      ),
     initialRoute:MainPage.id,
     routes: {
       RegisterPage.id : (context)=>RegisterPage(),
       LoginPage.id:(context)=>LoginPage(),
       MainPage.id:(context)=>MainPage(),
       PhoneRegisterPage.id:(context)=>PhoneRegisterPage()
     },
   );
  }
}
