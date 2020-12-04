import 'package:flutter/material.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(4.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[

            SizedBox(height: 20,),

            Text('PAIEMENT'),

            SizedBox(height: 20,),

            BrandDivider(),

            SizedBox(height: 16.0,),

            Text('$fares DZD', style: TextStyle(fontFamily: 'Brand-Bold', fontSize: 50),),

            SizedBox(height: 16,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Le montant ci-dessus correspond au total des tarifs à facturer au passager', textAlign: TextAlign.center,),
            ),

            SizedBox(height: 30,),

            Container(
              width: 230,
              child: TaxiButton(
                title: (paymentMethod == 'cash') ? 'PAY CASH' : 'CONFIRM',
                color: BrandColors.colorGreen,
                onPressed: (){

                  Navigator.pop(context, 'close');

                },
              ),
            ),

            SizedBox(height: 40,)
          ],
        ),
      ),
    );
  }
}