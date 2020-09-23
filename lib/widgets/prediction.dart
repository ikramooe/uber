import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tProject/datamodels/prediction.dart';

import '../brand-colors.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  PredictionTile({this.prediction});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(

        children: [
          SizedBox(height:8.0),
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
                    Text(prediction.mainText,overflow:TextOverflow.ellipsis,maxLines: 1,), 
                    SizedBox(height:2),
                    Text(prediction.secondaryText , overflow:TextOverflow.ellipsis,maxLines: 1)],
                ),
              )
            ],
          ),
          SizedBox(height:8.0),
        ],
      ),
    );
  }
}
