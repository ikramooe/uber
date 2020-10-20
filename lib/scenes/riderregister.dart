import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tProject/datamodels/company.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../brand-colors.dart';

class RegisterPage extends StatelessWidget {
  static const String id = "register";

  var NameController = TextEditingController();
  var EmailController = TextEditingController();
  var PhoneController = TextEditingController();
  var PasswordController = TextEditingController();
  List Entreprises = [];

  void getEntreprises() {
    FirebaseDatabase.instance
        .reference()
        .child('companies')
        .once()
        .then((DataSnapshot snapshot) {
      //here i iterate and create the list of objects
      Map<dynamic, dynamic> companies = snapshot.value;
      companies.forEach((key, value) {
        Entreprises.add(Company.fromJson(key, value));
      });
    });
  }

  void RegisterUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: EmailController.text, password: PasswordController.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 45),
                Image(
                  alignment: Alignment.center,
                  height: 100,
                  width: 100,
                  image: AssetImage("images/logo.png"),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: <Widget>[
                    TextField(
                      controller: NameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: 'Nom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    TextField(
                      controller: PhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    TextField(
                      controller: EmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: 'Nom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 50),
                    TaxiButton(
                        title: 'S\'inscrire',
                        color: BrandColors.colorGreen,
                        onPressed: () {
                          RegisterUser();
                        }),
                  ]),
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginPage.id, (route) => false);
                    },
                    child: Text('Already Have an account , login here'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
