import 'package:flutter/material.dart';
import 'package:tProject/scenes/mainpage.dart';
import 'package:tProject/widgets/taxibutton.dart';

import '../brand-colors.dart';
import 'branddivider.dart';

class CollectPayment extends StatelessWidget {
  
  final String paymentMethod;
  final String fares;

  CollectPayment({this.paymentMethod, this.fares});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(4.0),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Text('PAIEMENT'),
            SizedBox(
              height: 20,
            ),
            BrandDivider(),
            SizedBox(
              height: 16.0,
            ),
            Text(
              '$fares DZD',
              style: TextStyle(fontFamily: 'Brand-Bold', fontSize: 40),
            ),
            SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Le montant ci-dessus correspond au total de votre trajet',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              width: 230,
              child: TaxiButton(
                title: 'PAYER',
                color: BrandColors.colorGreen,
                onPressed: () {
                   
                  Navigator.of(context).popAndPushNamed(MainPage.id);
                },
              ),
            ),
            SizedBox(
              height: 40,
            )
          ],
        ),
      ),
    );
  }
}
