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
  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey();

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color:BrandColors.colorGreyclair,
        child: Column(
          children: <Widget>[
            // Menu button
            Container(
              height: 155,
              width: double.infinity,
              color: BrandColors.colorGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                  ),
                  Positioned(
                    top: 44,
                    left: 20,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MainPage()));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              )
                            ]),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                  ),
                  SizedBox(
                    width: 25,
                  ),
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
              
                  child: Card(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.share,color:Colors.black),

                          title: Text(ReferralHelper.link.shortUrl.toString(),style:TextStyle(color:Colors.black)),
                          
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
                        'Partagez le code pour gagner des points ',
                        style: TextStyle(
                            fontSize: 12, fontFamily: 'Brand-Bold',color:Colors.black),
                      ),
                    ),
                  ),
                  color: Colors.white,
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
