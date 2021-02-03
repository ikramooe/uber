import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:tProject/scenes/mainpage.dart';

import '../brand-colors.dart';

class Rating extends StatelessWidget {
  @override
  final ref;
  Rating({this.ref});
  Widget build(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: true, // set to false if you want to force a rating
        builder: (BuildContext context) {
          RatingDialog(
            icon: Image.asset(
              "images/logo.png",
              height: 80,
              width: 80,
            ), // set your own image/icon widget
            title: "Notation du chauffeur",
            description:
                "Appuyez sur une étoile pour définir votre note. Ajoutez plus de description ici si vous le souhaitez",
            submitButton: "VALIDER",
            positiveComment: "Nous sommes si heureux d'entendre :)", // optional
            negativeComment: "Nous sommes tristes d'entendre :(", // optional
            accentColor: BrandColors.colorOrangeclair, // optional
            onSubmitPressed: (int rating) {
              print("onSubmitPressed: rating = $rating");
              FirebaseFirestore.instance
                  .collection('rideRequests')
                  .doc(ref)
                  .update({'rating': rating});
              Navigator.of(context).popAndPushNamed(MainPage.id);
            },
          );
        });
  }
}
