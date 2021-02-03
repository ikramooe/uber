import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tProject/scenes/historypage.dart';
import 'package:tProject/scenes/mainpage.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/scenes/riderphone.dart';
import 'package:tProject/scenes/riderregister.dart';
import 'package:tProject/scenes/support.dart';

import 'datamodels/company.dart';
import 'dataproviders/appdata.dart';
import 'globals.dart';

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

  var companies =
      await FirebaseFirestore.instance.collection('Companies').get();

  companies.docs.forEach((element) {
    Entreprises_names.add(element.data()['code']);
    Entreprises.add(Company.fromJson(element.id, element.data()));
    //print(Entreprises);
  });
  print(Entreprises_names);
  currentFirebaseUser = await FirebaseAuth.instance.currentUser;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Brand-Regular'),
        initialRoute:currentFirebaseUser ==null ? RegisterPage.id: MainPage.id ,
        routes: {
          RegisterPage.id: (context) => RegisterPage(),
          
          HistoryPage.id: (context) => HistoryPage(),
          LoginPage.id: (context) => LoginPage(),
          MainPage.id: (context) => MainPage(),
          PhoneRegisterPage.id: (context) => PhoneRegisterPage()
          
        },
      ),
    );
  }
}
