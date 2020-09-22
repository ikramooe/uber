import 'package:flutter/cupertino.dart';
import 'package:tProject/datamodels/address.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress;
  void updatePickUpAddress(Address adresse) {
    pickupAddress = adresse;
    notifyListeners(); 
  }
}
