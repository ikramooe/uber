import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tProject/brand-colors.dart';
import 'package:tProject/datamodels/prediction.dart';
import 'package:tProject/dataproviders/appdata.dart';
import 'package:tProject/globals.dart';
import 'package:tProject/helpers/requesthelper.dart';
import 'package:tProject/widgets/prediction.dart';

class SearchPAGE extends StatefulWidget {
  @override
  _SearchPAGEState createState() => _SearchPAGEState();
}

class _SearchPAGEState extends State<SearchPAGE> {
  var pickupController = TextEditingController();
  var destinationController = TextEditingController();
  var focus = FocusNode();
  bool focused = false;

  var thisList = [];
  void setFocus() {
    if (!focused) FocusScope.of(context).requestFocus(focus);
    focused = true;
  }

  void searchPlace(String placeName) async {
    var thisLis = [];
    //print(placeName);
    //print(placeName.length);
    if (placeName.length > 1) {
      String $url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${placeName}&key=$mapkey&sessiontoken=1234567890&components=country:dz";
      var response = await RequestHelper.getRequest($url);

      if (response == "failed") return;

      if (response['status'] == "OK") {
        var predictionjson = response['predictions'];
        thisLis = (predictionjson as List)
            .map((e) => Prediction.fromJson(e))
            .toList();
      }
    }
    setState(() {
      thisList = [];
      thisList = thisLis;
    });
    
  }

  Widget build(BuildContext context) {
    setFocus();
    String address =
        Provider.of<AppData>(context).pickupAddress.placeName ?? '';
    pickupController.text = address;
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(children: <Widget>[
        Container(
          height: 210,
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5.0,
              spreadRadius: 0.5,
              offset: Offset(0.7, 0.7),
            )
          ]),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 48),
            child: Column(children: <Widget>[
              SizedBox(
                height: 2,
              ),
              Stack(
                children: <Widget>[
                  GestureDetector(
                      onTap: () => {Navigator.pop(context)},
                      child: Icon(Icons.arrow_back)),
                  Center(
                    child: Text(
                      'Destination',
                      style: TextStyle(fontSize: 20, fontFamily: 'Brand-Bold'),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                children: <Widget>[
                  Image.asset('images/pickicon.png', height: 16, width: 16),
                  SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: BrandColors.colorLightGrayFair,
                          borderRadius: BorderRadius.circular(4)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextField(
                          controller: pickupController,
                          decoration: InputDecoration(
                              hintText: address,
                              fillColor: BrandColors.colorLightGrayFair,
                              filled: true,
                            border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.only(left: 10, top: 8, bottom: 8)),
                        ),
                      ),
                    ),
                  )

                  // second row
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: <Widget>[
                  Image.asset('images/destination.png', height: 16, width: 16),
                  SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: BrandColors.colorLightGrayFair,
                          borderRadius: BorderRadius.circular(4)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextField(
                          onChanged: (value) {
                            searchPlace(value);
                          },
                          controller: destinationController,
                          decoration: InputDecoration(
                              hintText: 'where ',
                              fillColor: BrandColors.colorLightGrayFair,
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.only(left: 10, top: 8, bottom: 8)),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ]),
          ),
        ),
        //list view
        (thisList.length > 0)
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: ListView.separated(
                  padding: EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    //print(thisList[index].mainText);
                    //print(thisList[index].secondaryText);
                    return PredictionTile(
                      prediction: thisList[index],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(),
                  itemCount: thisList.length,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                ),
              )
            // PredictionTile()

            : Container()
      ]),
    ));
  }
}
