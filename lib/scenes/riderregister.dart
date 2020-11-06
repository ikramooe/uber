import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:tProject/datamodels/company.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/scenes/riderphone.dart';
import 'package:tProject/widgets/taxibutton.dart';
import 'package:toast/toast.dart';

import '../brand-colors.dart';
import '../globals.dart';
import 'mainpage.dart';

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
  String smsCode;
  String verificationCode;
  String otp = "";

  var errorText;
  bool checkCode = false;
  int index;

  var phoneIsoCode;

  String phoneNumber;

  bool validNom = true;
  bool validPrenom = true;
  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      phoneNumber = number;
      PhoneController.text = number;
    });
  }

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
      print(' $checkCode');
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

  void showToast(String msg, {int duration, int gravity}) {
    Toast.show(msg, context, duration: duration, gravity: gravity);
  }

  void RegisterUser(index) async {
    print('iam here register $index');
    //print(currentFirebaseUser.uid);
    NameController.text == "" ? validNom = false : validNom = true;
    PrenomController.text == "" ? validPrenom = false : validPrenom = true;
    if (PhoneController.text == "") {
      showToast('phone number is required', gravity: Toast.TOP);
    }
    if (!validNom || !validPrenom || PhoneController.text == "") return;
    var verifyPhoneNumber = await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+213" + PhoneController.text,
      // successful verification
      verificationCompleted: (PhoneAuthCredential credential) {
        print("success");
      },
      // verification failed
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
      },
      // sms sent
      codeSent: (String verificationId, int resendToken) {
        this.verificationCode = verificationId;
        print("code sent: " + verificationId);
        otpDialogBox(context).then((value) {});
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    await verifyPhoneNumber;
  }

  void _signIn(String smsCode) async {
    var _authCredential = PhoneAuthProvider.getCredential(
        verificationId: verificationCode, smsCode: smsCode);
    FirebaseAuth.instance
        .signInWithCredential(_authCredential)
        .catchError((error) {});

    FirebaseAuth.instance.authStateChanges().listen((User user) async {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        //save user information to database
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'nom': NameController.text,
          'prenom': PrenomController.text,
          'entreprise': company_name,
          'code': CodeController.text
        });

        if (index != null) {
          var currentCompany = await FirebaseFirestore.instance
              .collection('Companies')
              .doc(current.id);

          Map usersCode = {
            'user': user.uid,
            'code': CodeController.text,
          };
          current.codes.removeAt(index);
          current.codes.add(usersCode);

          currentCompany.set({'codes': current.codes, 'name': current.name});

          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(
                  {'entreprise': company_name, 'code': CodeController.text});
        }
        Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false);
      }
    });
  }

  otpDialogBox(BuildContext context) {
    Pin pin = new Pin();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('votre code '),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              // pin input
              child: pin,
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _signIn(pin.code);
                },
                child: Text(
                  'Submit',
                ),
              ),
            ],
          );
        });
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
                          errorText: validNom == false
                              ? 'Value Can\'t Be Empty'
                              : null,
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
                          errorText: validPrenom == false
                              ? 'Value Can\'t Be Empty'
                              : null,
                          labelText: 'Prenom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    InternationalPhoneInput(
                      onPhoneNumberChange: onPhoneNumberChange,
                      initialSelection: phoneIsoCode,
                      enabledCountries: ['+213'],
                      labelText: "Telephone",
                      showCountryCodes: true,
                      decoration: InputDecoration(fillColor: Colors.white),
                      showCountryFlags: true,
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
