import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tProject/datamodels/address.dart';
import 'package:tProject/datamodels/prediction.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/helpers/requesthelper.dart';

import '../brand-colors.dart';
import '../globals.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  PredictionTile({this.prediction});
  void getPlaceDetails(String placeID, context) async {
    
    var pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: true);
    
    pr.style(
        message: 'Searching...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    
    //await pr.show();
    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeID&key=$mapkey";
    var response = await RequestHelper.getRequest(url);
  
    //pr.hide();
    if (response == "failed") return;
    if (response['status'] == "OK") {
      //print(response['result']['name']);
      Address thisPlace = Address();

      thisPlace.placeName = response['result']['name'];
      thisPlace.placeId = placeID;
      thisPlace.latitude = response['result']['geometry']['location']['lat'];
      thisPlace.longitude = response['result']['geometry']['location']['lng'];

      Provider.of<AppData>(context, listen: false)
          .updateDestinationAddress(thisPlace);
      //print("olaaa");
      //print("meeee"+thisPlace.placeName);

      Navigator.pop(context,'getDirection');
    }
  }

  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0),
      onPressed: () {
        getPlaceDetails(prediction.placeId, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Icon(Icons.location_on, color: BrandColors.colorDimText),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        prediction.mainText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 2),
                      Text(prediction.secondaryText,
                          overflow: TextOverflow.ellipsis, maxLines: 1)
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}
