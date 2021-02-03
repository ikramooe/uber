import 'package:tProject/datamodels/nearbydriver.dart';

class FireHelper {
  static List<NearByDriver> nearbyDriverList = [];

  static void removeFromList(String key) {
    int index = nearbyDriverList.indexWhere((element) => element.key == key);
    if(index >=0)
    nearbyDriverList.removeAt(index);
  }

  static void updateNearbyLocation(NearByDriver driver) {
    int index =
        nearbyDriverList.indexWhere((element) => element.key == driver.key);
    print('index $index');

    if (index >= 0) {
      nearbyDriverList[index].longitude = driver.longitude;
      nearbyDriverList[index].latitude = driver.latitude;
      nearbyDriverList[index].distance = driver.distance;
      
    } else
      nearbyDriverList.add(driver);
    nearbyDriverList.sort((a, b) => a.distance.compareTo(b.distance));

  }
}
