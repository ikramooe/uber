import 'package:flutter/cupertino.dart';
import 'package:tProject/datamodels/address.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress;
  Address destinationAddress;
  void updatePickUpAddress(Address adresse) {
    pickupAddress = adresse;
    notifyListeners();
  }

  void updateDestinationAddress(Address destination) {
    destinationAddress = destination;
    notifyListeners();
  }
}
