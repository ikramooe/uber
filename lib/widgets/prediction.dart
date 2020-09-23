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
      child: Row(
        children: <Widget>[
          Icon(Icons.location_on, color: BrandColors.colorDimText),
          SizedBox(
            width: 12,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[Text(prediction.mainText), Text(prediction.secondaryText)],
          )
        ],
      ),
    );
  }
}
