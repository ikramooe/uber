import 'package:flutter/cupertino.dart';
import 'package:tProject/datamodels/address.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress;
  void updatePickUpAddress(Address adresse) {
    print("heeerreeeeeee");
    print(adresse);
    pickupAddress = adresse;
    print(pickupAddress.placeName);
    notifyListeners();
  }
}
