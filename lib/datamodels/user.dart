import 'package:firebase_database/firebase_database.dart';

class Userx {
  String phone;
  String id;
  Userx(){
    id="";
    phone="";
  }
  
  Userx.fromSnapshot(DataSnapshot snapshot) {
    this.id = snapshot.key;
    this.phone = snapshot.value['phone'];
  }
}
