import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:sms_consent/sms_consent.dart';

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
  int _otpCodeLength = 6;
  bool _isLoadingButton = false;
  bool _enableButton = false;
  bool numberExists = true;
  String signature = "{{ app signature }}";
  String otpCode = "";

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _receivedCode;

  var code;

  String receivedCode = "";

  var _codeController = TextEditingController();

  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

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
  int _forceResendingToken;
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

  void checkifHasAccount(String phone) async {
    
    var res = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: '+213'+phone)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        print(querySnapshot.docs);
        print(querySnapshot.size);
        print(querySnapshot.docs.length);
        numberExists = querySnapshot.docs.length > 0;
      });
    });

    print('i am res');
    print(res);
  }

  void RegisterUser() async {
    if (PhoneController.text == "") {
      showToast('phone number is required', gravity: Toast.TOP);
    }
    await checkifHasAccount(PhoneController.text);
    print(numberExists);
    if (numberExists == false) {
      showToast('Veuillez vous inscrire', gravity: Toast.TOP);
      Navigator.pushNamedAndRemoveUntil(
          context, RegisterPage.id, (route) => false);
    } else {
      var verifyPhoneNumber = await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+213" + PhoneController.text,
        timeout: Duration(seconds: 60),
        forceResendingToken: _forceResendingToken,

        verificationCompleted: (PhoneAuthCredential credential) {
          print("success");
        },
        // verification failed
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            print('The provided phone number is not valid.');
          }
        },

        codeSent: (
          String verificationId,
          int resendToken,
        ) async {
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

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      await verifyPhoneNumber;
    }
  }

  void _signIn(String smsCode) async {
    var _authCredential = PhoneAuthProvider.getCredential(
        verificationId: verificationCode, smsCode: smsCode);
    FirebaseAuth.instance.signInWithCredential(_authCredential).then((result) {
      print(result);
      Navigator.pushNamedAndRemoveUntil(context, MainPage.id, (route) => false);
    });

    FirebaseAuth.instance.authStateChanges().listen((User user) async {
      if (user == null) {
        await FirebaseAuth.instance.signInWithCredential(_authCredential);
        print('User is currently signed out!');
      } else {
        showToast('veuillez créer un compte');
        Navigator.pushNamedAndRemoveUntil(
            context, RegisterPage.id, (route) => false);
      }
    });
  }

  otpDialogBox(BuildContext context) {
    Pin pin = new Pin();
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Code Reçu'),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              // pin input
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'xxxxxx'),
              ),
            ),
            contentPadding: EdgeInsets.all(4.0),
            actions: <Widget>[
              Row(children: <Widget>[
                
                FlatButton(
                  onPressed: () {
                    RegisterUser();
                  },
                  child: Text(
                    'resend code',
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _signIn(_codeController.text);
                  },
                  child: Text(
                    'valider',
                  ),
                ),
                
              ])
            ],
          );
        });
  }

  Widget _setUpButtonChild() {
    if (_isLoadingButton) {
      return Container(
        width: 19,
        height: 19,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      return Text(
        "Verify",
        style: TextStyle(color: Colors.white),
      );
    }
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
                  height: 130,
                  width: 140,
                  image: AssetImage("images/logo.png"),
                ),
                SizedBox(
                  height: 30,
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
                      height: 30,
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
