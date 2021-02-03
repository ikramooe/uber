import 'package:flutter/material.dart';

class TaxiButton extends StatelessWidget {
  final String title;
  final Color color;
  final Color textcol ;
  final Function onPressed;
  TaxiButton({this.title, this.color,this.onPressed,this.textcol=Colors.white});
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      shape: new RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(10),
      ),
      color: color,
      textColor: textcol,
      child: Container(
        height: 20,
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontFamily: 'Brand-Bold'),
          ),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
