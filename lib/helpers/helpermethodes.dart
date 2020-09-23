import 'package:connectivity/connectivity.dart';
import 'package:provider/provider.dart';
import 'package:tProject/datamodels/address.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/globals.dart';
import 'package:geolocator/geolocator.dart';

import 'requesthelper.dart';

class HelperMethods {
  static Future<String> findCoordinatesAddress(
      Position position, context) async {
    String placeAddress = "";

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey";

    var response = await RequestHelper.getRequest(url);
    //print(response);
    if (response != 'failed') {
      placeAddress = response['results'][0]['formatted_address'];
      //print(placeAddress);
      Address pickupAddress = new Address();
      pickupAddress.longitude = position.longitude;
      pickupAddress.latitude = position.latitude;
      pickupAddress.placeFormattedAddress = placeAddress;
      //print("pickup");
      //print(placeAddress);
      Provider.of<AppData>(context, listen: false)
          .updatePickUpAddress(pickupAddress);
    }
    return placeAddress;
  }
}
