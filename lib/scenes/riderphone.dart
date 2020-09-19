import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:tProject/scenes/riderlogin.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../brand-colors.dart';

class PhoneRegisterPage extends StatefulWidget {
  @override
  static const String id = "registerphone";
  _PhoneRegisterState createState() => _PhoneRegisterState();
}

class _PhoneRegisterState extends State<PhoneRegisterPage> {
  @override
  String phoneNumber = "";
  String smsCode;
  String verificationCode;
  String otp = "";
  var PhoneController = TextEditingController();

  String currentText;

  var formKey;


  String status;
  Future<void> _submit() async {
    var verifyPhoneNumber = await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+213796580458",
      // successful verification
      verificationCompleted: (PhoneAuthCredential credential) {
        print("success");
      },
      // verification failed
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
        ;
      },
      // sms sent
      codeSent: (String verificationId, int resendToken) {
        this.verificationCode = verificationId;
        print("code sent: " + verificationId);
        otpDialogBox(context).then((value) {});
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        
      },
    );
    await verifyPhoneNumber;
  }

  void _signIn(String smsCode) async {
    var _authCredential = PhoneAuthProvider.getCredential(
        verificationId: verificationCode, smsCode: smsCode);
    FirebaseAuth.instance
        .signInWithCredential(_authCredential)
        .catchError((error) {
      setState(() {
        status = 'Something has gone wrong, please try later';
      });
    });
  }

// check code dialog box
  otpDialogBox(BuildContext context) {
    Pin pin = new Pin();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter your OTP'),
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

//end dialog box
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
                      controller: PhoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => phoneNumber = value,
                      decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )),
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                  ]),
                ),
                RaisedButton(
                    onPressed: () {
                      _submit();
                    },
                    child: Text('Verifier'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class Pin  used in dialog
class Pin extends StatelessWidget {
  @override
  String code;
  Pin() {}
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: PinCodeTextField(
            appContext: context,

            pastedTextStyle: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: 6,
            obscureText: false,
            animationType: AnimationType.fade,
            validator: (v) {
              if (v.length < 3) {
                return "I'm from validator";
              } else {
                return null;
              }
            },
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(5),
              fieldHeight: 50,
              fieldWidth: 40,
            ),
            animationDuration: Duration(milliseconds: 300),
            backgroundColor: Colors.white,
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            onCompleted: (v) {
              print("Completed");
            },
            // onTap: () {
            //   print("Pressed");
            // },
            onChanged: (value) {
              print(value);
              code = value;
            },
            beforeTextPaste: (text) {
              print("Allowing to paste $text");
              //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
              //but you can show anything you want here, like your pop up saying wrong paste format or etc
              return true;
            },
          )),
    );
  }
}
