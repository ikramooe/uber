class Company {
  String name;
  String code;
  String promo;
  String id;
  List codes;

  Company.fromJson(key, Map data) {
    this.code = data['code'];
    this.name = data['name'];
    this.promo = data['promo'];
    this.id = key;
    this.codes = data['codes'];
  }
}
