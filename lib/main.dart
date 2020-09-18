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
            appId: '1:658445430000:ios:42ffd961aee52cbc69e635',
            apiKey: 'AIzaSyCUSemoprJW5qYL2YCDlVJbjHHj9qBHMyQ',
            projectId: 'ziouan-vite-vite',
            messagingSenderId: '658445430000',
            databaseURL: 'https://ziouan-vite-vite.firebaseio.com',
          )
        : FirebaseOptions(
            appId: '1:658445430000:android:0e42bdd1f974e92769e635',
            apiKey: 'AIzaSyAYMGtiSSQXoEzYruYwej05H3hsHRHlmRc',
            messagingSenderId: '297855924061',
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
     home:MainPage()
   );
  }
}
