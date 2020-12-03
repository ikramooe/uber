import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:tProject/scenes/riderphone.dart';
import 'package:tProject/scenes/riderregister.dart';
import 'package:tProject/widgets/taxibutton.dart';
import 'package:toast/toast.dart';

import '../brand-colors.dart';

import 'mainpage.dart';

class LoginPage extends StatefulWidget {
  static const String id = "login";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var NameController = TextEditingController();

  var PrenomController = TextEditingController();

  var PhoneController = TextEditingController();

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

  void showToast(String msg, {int duration, int gravity}) {
    Toast.show(msg, context, duration: duration, gravity: gravity);
  }

  void RegisterUser() async {
    if (PhoneController.text == "") {
      showToast('phone number is required', gravity: Toast.TOP);
    }
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
    FirebaseAuth.instance.signInWithCredential(_authCredential)
      .then((result) {
        print(result);
        Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false);
      });

    FirebaseAuth.instance.authStateChanges().listen((User user) async {
      if (user == null) {
        await FirebaseAuth.instance.signInWithCredential(_authCredential);
        print('User is currently signed out!');
      } else {
        //showToast('veuillez créer un compte');
        Navigator.pushNamedAndRemoveUntil(
            context, RegisterPage.id, (route) => false);
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
      backgroundColor: BrandColors.colorGreyclair,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 45),
                Image(
                  alignment: Alignment.center,
                  height: 180,
                  width: 180,
                  image: AssetImage("images/logo.png"),
                ),
                SizedBox(
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: <Widget>[
                    InternationalPhoneInput(
                      onPhoneNumberChange: onPhoneNumberChange,
                      labelStyle: TextStyle(color: Colors.white),
                      initialSelection: phoneIsoCode,
                      enabledCountries: ['+213'],
                      labelText: "Telephone",
                      showCountryCodes: true,
                      hintStyle: TextStyle(color: Colors.white),
                      showCountryFlags: true,
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    TaxiButton(
                        title: 'Se connecter',
                        color: BrandColors.colorOrangeclair,
                        onPressed: () {
                          RegisterUser();
                        }),
                    FlatButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, RegisterPage.id, (route) => false);
                        },
                        child: Text(
                            'Vous n\'avez pas de compte ? Créer un compte '))
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
