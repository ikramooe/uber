import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:sms_consent/sms_consent.dart';
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
var _codeController = TextEditingController();

  var company_name = Entreprises_names[0];
  Company current;
  String smsCode;
  String verificationCode;
  String otp = "";
  String signature = "{{ app signature }}";
  String otpCode = "";


  var errorText;
  bool checkCode = false;
  int index;
  
  var phoneIsoCode;

  String phoneNumber;

  bool validNom = true;
  bool validPrenom = true;

  String receivedCode="";
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
    NameController.text == "" ? validNom = false : validNom = true;
    PrenomController.text == "" ? validPrenom = false : validPrenom = true;
    if (PhoneController.text == "") {
      showToast('le numéro de téléphone est requis', gravity: Toast.TOP);
    }
    if (!validNom || !validPrenom || PhoneController.text == "") return;
    var verifyPhoneNumber = await FirebaseAuth.instance.verifyPhoneNumber(
      
      phoneNumber: "+213" + PhoneController.text,
      timeout: const Duration(seconds: 5),
      // successful verification
      verificationCompleted: (PhoneAuthCredential credential) {
        print("success");
      },
      // verification failed
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('Le numéro de téléphone fourni n\'est pas valide.');
        }
      },
      // sms sent
      codeSent: (String verificationId, int resendToken) async {
        this.verificationCode = verificationId;
        print("code sent: " + verificationId);
        otpDialogBox(context).then((value) {});

        try {
          receivedCode = await SmsConsent.startSMSConsent();
          setState(() {
            otpCode = receivedCode;
            _codeController.text = receivedCode;
          });
        } on PlatformException {
          receivedCode = 'Failed to get the code.';
        }
        print(receivedCode);
      },

       

      codeAutoRetrievalTimeout: (String verificationId) {
        print(' auto retreival time out ');
        this.verificationCode = verificationId;

      },
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
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'phone': user.phoneNumber});
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'phone': user.phoneNumber,
            'nom': NameController.text,
            'prenom': PrenomController.text,
            'trips': [],
            'entreprise':""
          });
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
            title: Text('votre code'),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              // pin input
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'xxxxxx'),
              ),
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _signIn(pin.code);
                },
                child: Text(
                  'Valider',
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
                SizedBox(height: 35),
                Image(
                  alignment: Alignment.center,
                  height: 120,
                  width: 140,
                  image: AssetImage("images/logo.png"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: <Widget>[
                    TextField(
                      controller: NameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          errorText: validNom == false
                              ? 'Nom ne peut pas etre vide'
                              : null,
                          labelText: 'Nom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.white,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    TextField(
                      controller: PrenomController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          errorText: validPrenom == false
                              ? 'Prenom ne peut pas etre vide'
                              : null,
                          labelText: 'Prenom',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.white,
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
                    TaxiButton(
                        title: 'S\'inscrire',
                        color: BrandColors.colorOrangeclair,
                        onPressed: () {
                          RegisterUser(null);
                        }),
                  ]),
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginPage.id, (route) => false);
                    },
                    child:
                        Text('Vous avez déjà un compte ? Connectez-vous ici'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
