import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tProject/widgets/branddivider.dart';

import '../brand-colors.dart';

class Support extends StatelessWidget {
  @override
  
  Widget build(BuildContext context) {
    final id = "support";
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
        backgroundColor: BrandColors.colorOrange,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: Container(
        child:Column (
          children: [
            Container(
              height: 200,
              width: double.infinity,
              child: Image.asset('images/support.png',height: 120,width: 90,)
              ),
            
            SizedBox(height: 30),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  color: Colors.white,
                  child: Card(
                    color: BrandColors.colorOrange,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.mail,color:Colors.white),

                          title: Text('mail',style:TextStyle(color:Colors.white)),
                          
                        ),
                        ListTile(
                          leading: Icon(Icons.phone,color:Colors.white),

                          title: Text('phone',style:TextStyle(color:Colors.white)),
                          
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),    


        ],)
              ),
    );
  }
}
