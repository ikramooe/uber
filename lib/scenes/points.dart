import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:tProject/brand-colors.dart';
import 'package:tProject/helpers/referralhelper.dart';
import 'package:tProject/scenes/mainpage.dart';
import 'package:tProject/helpers/helpermethodes.dart';
import 'package:tProject/widgets/branddivider.dart';



class MyPoints extends StatefulWidget {
  static const String id = "points";
  @override
  _MyPointsState createState() => _MyPointsState();
}

class _MyPointsState extends State<MyPoints> with TickerProviderStateMixin {

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Points'),
        backgroundColor: BrandColors.colorOrange,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
      ),
      
      body: Container(
        color:BrandColors.colorOrange,
        child: Column(
          children: <Widget>[
            // Menu button
            Container(
              height: 100,
              width: double.infinity,
              color: BrandColors.colorGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Text('600 Points', style:TextStyle(color:Colors.white,fontSize:20) ),
                ],
              ),
            ),
            BrandDivider(),
            SizedBox(height: 30),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  color: BrandColors.colorGrey,
                  child: Card(
                    color: BrandColors.colorGrey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.share,color:Colors.white),

                          title: Text(ReferralHelper.link.shortUrl.toString(),style:TextStyle(color:Colors.white)),
                          
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RaisedButton(
                  onPressed: () {
                    Share.share(ReferralHelper.link.shortUrl.toString());
                  },
                  child: Container(
                    height: 20,
                    child: Center(
                      child: Text(
                        'Partagez votre code pour gagner des points ',
                        style: TextStyle(
                            fontSize: 12, fontFamily: 'Brand-Bold',color:Colors.white),
                      ),
                    ),
                  ),
                  color: BrandColors.colorGrey,
                  shape: new RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    HelperMethods.getCurrent();
  }
}
