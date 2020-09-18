import 'package:flutter/material.dart';
import 'package:tProject/brand-colors.dart';


class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                SizedBox(height:50),
                Image(
                  alignment: Alignment.center,
                  height: 100,
                  width: 100, 
                  image:AssetImage("images/logo.png"),
                ),
                SizedBox(height:30,),
                Text('Sign in as Rider',
                    textAlign: TextAlign.center,
                    style:TextStyle(fontSize: 25,fontFamily:'Brand-Bold' ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                  children: <Widget>[ 
                    TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email' ,
                      labelStyle: TextStyle(
                        fontSize: 14.0
                      ),
                      hintStyle: TextStyle(
                       color:Colors.grey,

                      )
                       
                    ),
                    style: TextStyle(
                      fontSize: 14
                    ),

                  ),
                    SizedBox(height:10),
                    TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password' ,
                      labelStyle: TextStyle(
                        fontSize: 14.0
                      ),
                      hintStyle: TextStyle(
                       color:Colors.grey,

                      )
                       
                    ),
                    style: TextStyle(
                      fontSize: 14
                    ),

                  ),
                  SizedBox(height:50),
                  RaisedButton(
                  shape:new RoundedRectangleBorder(
                    borderRadius:new BorderRadius.circular(25),

                  ),
                  color:BrandColors.colorGreen,
                  textColor: Colors.white,
                  child: Container(
                    height: 50,
                    child: Center(
                      child: Text(
                        'Login',
                        style:TextStyle(
                             fontSize: 18,
                             fontFamily: 'Brand-Bold'
                        ),

                      ),
                    ),
                  ),
                  onPressed: (){},

                )
 
             
                  
                  ]),
                ),
                FlatButton(onPressed: () { },
                child: Text('Don\'t Have an account , sign up here'))
               ],
            ),
          ),
        ),
      ),
    );
  }
}
