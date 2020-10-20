import 'package:firebase_database/firebase_database.dart';

class Company {
  String name;
  String code;
  String promo;
  String id;

  Company.fromJson(key, Map data) {
    this.code = data['code'];
    this.name = data['name'];
    this.promo = data['promo'];
    this.id = data['key'];
  }
}
