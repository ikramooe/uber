import 'package:firebase_database/firebase_database.dart';

class Userx {
  String phone;
  String id;
  String nom;
  String prenom;
  String entreprise;
  String code;
  DateTime date_naiss;
  List trips;

  Userx() {
    id = "";
    phone = "";
    nom = "";
    prenom = "";
    entreprise = "";
  }

  Userx.fromSnapshot(DataSnapshot snapshot) {
    this.id = snapshot.key;
    this.phone = snapshot.value['phone'];
  }
}
