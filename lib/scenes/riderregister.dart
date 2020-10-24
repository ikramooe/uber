import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tProject/datamodels/company.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../brand-colors.dart';
import '../globals.dart';

class RegisterPage extends StatefulWidget {
  static const String id = "register";

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  var NameController = TextEditingController();

  var PrenomController = TextEditingController();

  var PhoneController = TextEditingController();

  var CodeController = TextEditingController();

  var company_name = Entreprises_names[0];
  Company current;

  var errorText;
  bool checkCode = false;
  int index;

  void checkCodeCompany() async {
    checkCode = false;
    if (company_name != "" && CodeController.text != "") {
      int index = Entreprises_names.indexOf(company_name);
      print(index);
      print(Entreprises.elementAt(index - 1));
      current = Entreprises.elementAt(index - 1);
      print('olaaaa');
      //print(current.codes);
      for (Map element in current.codes) {
        if (element['code'] == CodeController.text) {
          setState(() {
            checkCode = true;
            index = current.codes.indexOf(element);
            print(index);
          });
          break;
        }
      }
      print('frfrfrf $checkCode');
      if (checkCode == false)
        setState(() {
          errorText = 'non valide';
        });
      else {
        setState(() {
          errorText = '';
        });
        RegisterUser(index);
      }
    } else
      RegisterUser(index);
  }

  void RegisterUser(index) async {
    print('iam here register $index');
    DatabaseReference userRef = FirebaseDatabase.instance
        .reference()
        .child('users/${currentFirebaseUser.uid}');

    userRef.child('nom').set(NameController.text);
    userRef.child('prenom').set(PrenomController.text);
    userRef.child('entreprise').set(company_name);
    userRef.child('code').set(CodeController.text);
    print('i am current');
    print(current.id);
    var currentCompany = await FirebaseFirestore.instance
        .collection('Companies')
        .doc(current.id);

    Map usersCode = {
      'user': currentFirebaseUser.uid,
      'code': CodeController.text,
    };
    print(index);
    if (index != null) {
      current.codes.removeAt(index);
      current.codes.add(usersCode);

      currentCompany.set({'codes': current.codes,'name':current.name});
      FirebaseDatabase.instance
          .reference()
          .child('users/${currentFirebaseUser.uid}')
          .update({'entreprise': current.name, 'code': CodeController.text});
    }

    /*
    currentCompany.update('codes').then((value){
         if(value.code==CodeController.text)
             value.user="EEEE";
    })
    */

    //print(currentCompany.data());
    //current_company.data().update('user', (value) => currentFirebaseUser.uid);
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
                      controller: PrenomController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: 'Prenom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      isExpanded: true,
                      isDense: false,
                      value: company_name,
                      style: TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 0,
                      ),
                      onChanged: (String newValue) {
                        setState(() {
                          company_name = newValue;
                        });
                      },
                      items: Entreprises_names.map<DropdownMenuItem<String>>(
                          (item) {
                        return DropdownMenuItem<String>(
                          child: new Text(item),
                          value: item.toString(),
                        );
                      }).toList(),
                    ),
                    company_name != ' '
                        ? TextField(
                            controller: CodeController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                labelText: 'votre code',
                                labelStyle: TextStyle(fontSize: 14.0),
                                errorStyle: TextStyle(),
                                errorText: errorText,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                )),
                            style: TextStyle(fontSize: 14),
                          )
                        : Container(),
                    SizedBox(
                      height: 20,
                    ),
                    TaxiButton(
                        title: 'S\'inscrire',
                        color: BrandColors.colorGreen,
                        onPressed: () {
                          checkCodeCompany();
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
