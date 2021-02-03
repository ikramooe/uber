import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:tProject/datamodels/company.dart';
import 'package:tProject/helpers/helpermethodes.dart';
import 'package:tProject/scenes/riderphone.dart';
import 'package:tProject/widgets/taxibutton.dart';
import 'package:toast/toast.dart';
import '../brand-colors.dart';
import '../globals.dart';
import 'mainpage.dart';

class ProfilePage extends StatefulWidget {
  static const String id = "profile";

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var NameController = TextEditingController();
  var PrenomController = TextEditingController();
  var PhoneController = TextEditingController();
  var CodeController = TextEditingController();
  var company_name = Entreprises_names[0];
  DateTime selectedDate = DateTime.now();

  Company current;
  String smsCode;
  String verificationCode;
  String otp = "";

  var errorText;
  bool checkCode = false;
  int index;
  String phoneNumber;
  var phoneIsoCode;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2120));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  void checkCodeCompany() async {
    checkCode = false;
    print(CodeController.text);
    if (CodeController.text != currentUserInfo.code) if (CodeController.text !=
        "") {
      index = Entreprises_names.indexOf(CodeController.text);
      print('i am index $index');
      if (index >= 0) {
        current = Entreprises.elementAt(index);
        for (Map element in current.codes) {
          print(current.codes);
          if (element['code'] == PhoneController.text) {
            setState(() {
              checkCode = true;
              index = current.codes.indexOf(element);
            });
            break;
          }
        }
      }
      if (checkCode == false)
        setState(() {
          errorText = 'non valide';
        });
      else {
        setState(() {
          errorText = '';
        });
        updateUser(index);
      }
    } else
      updateUser(null);
    else
      updateUser(null);
  }

  void showToast(String msg, {int duration, int gravity}) {
    Toast.show(msg, context, duration: duration, gravity: gravity);
  }

  void _signIn() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentFirebaseUser.uid)
        .update({
      'nom': NameController.text,
      'prenom': PrenomController.text,
      'entreprise': CodeController.text,
      'date_naiss': selectedDate
    });
    if (index != null && index>=0) {
      var currentCompany =
          FirebaseFirestore.instance.collection('Companies').doc(current.id);
      Map usersCode = {
        'user': currentFirebaseUser.uid,
        'phone': PhoneController.text,
      };
      current.codes.removeAt(index);
      current.codes.add(usersCode);
      currentCompany.update({'codes': current.codes});

      FirebaseFirestore.instance
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .update({'entreprise': CodeController.text});
    }
    showToast('Profile modifié avec succés');
    HelperMethods.getCurrent();
    //Navigator.pushNamedAndRemoveUntil(context, MainPage.id, (route) => false);
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
                  _signIn();
                },
                child: Text(
                  'Submit',
                ),
              ),
            ],
          );
        });
  }

  void updateUser(index) async {
    NameController.text == "" ? validNom = false : validNom = true;
    PrenomController.text == "" ? validPrenom = false : validPrenom = true;
    if (PhoneController.text == "") {
      showToast('phone number is required', gravity: Toast.TOP);
    }
    if (!validNom || !validPrenom || PhoneController.text == "") return;
    if (PhoneController.text != currentUserInfo.phone) {
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
        codeSent: (String verificationId, int resendToken) {
          this.verificationCode = verificationId;
          print("code sent: " + verificationId);
          otpDialogBox(context).then((value) {});
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      await verifyPhoneNumber;
    } else
      _signIn();
  }

  initState() {
    super.initState();
    NameController.text = currentUserInfo.nom;
    PrenomController.text = currentUserInfo.prenom;
    PhoneController.text = currentUserInfo.phone;
    if (currentUserInfo.entreprise != "AUCUNE" &&
        currentUserInfo.entreprise != "") {
      CodeController.text = currentUserInfo.entreprise;
    }
    if (currentUserInfo.date_naiss != null)
      selectedDate = currentUserInfo.date_naiss;
  }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      phoneNumber = number;
      PhoneController.text = number;
    });
  }

  bool validNom = true;
  bool validPrenom = true;

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: AppBar(
          title: Text('Profile'),
          backgroundColor: BrandColors.colorOrange,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.keyboard_arrow_left),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              /*
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Stack(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => {Navigator.pop(context)},
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              )
                            ]),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              */
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                    child: TextField(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                    child: TextField(
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
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      _selectDate(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                      child: TextField(
                        keyboardType: TextInputType.name,
                        enabled: false,
                        controller: TextEditingController(
                            text: "${selectedDate.toLocal()}".split(' ')[0]),
                        decoration: InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: 'Date de naissance ',
                            labelStyle: TextStyle(fontSize: 14.0),
                            hintStyle: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                    child: InternationalPhoneInput(
                      onPhoneNumberChange: onPhoneNumberChange,
                      initialSelection: phoneIsoCode,
                      enabledCountries: ['+213'],
                      labelText: "Telephone",
                      showCountryCodes: true,
                      initialPhoneNumber: PhoneController.text,
                      decoration: InputDecoration(fillColor: Colors.white),
                      showCountryFlags: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                    child: Text(
                        'si vous faites partie d\'une entreprise introduisez votre code'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                    child: TextField(
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
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                    child: TaxiButton(
                        title: 'Modifier',
                        color: BrandColors.colorGrey,
                        onPressed: () {
                          checkCodeCompany();
                        }),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
