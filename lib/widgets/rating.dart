import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rating_dialog/rating_dialog.dart';

class Rating extends StatelessWidget {
  @override
  final ref;
  Rating({this.ref});
  Widget build(BuildContext context) {
    return RatingDialog(
      icon: const FlutterLogo(
          size: 100, colors: Colors.red), // set your own image/icon widget
      title: "Notation du chauffeur",
      description:
          "Appuyez sur une étoile pour définir votre note. Ajoutez plus de description ici si vous le souhaitez",
      submitButton: "VALIDER",
      positiveComment: "Nous sommes si heureux d'entendre :)", // optional
      negativeComment: "Nous sommes tristes d'entendre :(", // optional
      accentColor: Colors.red, // optional
      onSubmitPressed: (int rating) {
        print("onSubmitPressed: rating = $rating");
        FirebaseFirestore.instance
              .collection('rideRequests')
              .doc(ref)
              .update({'rating': rating});
        Navigator.pop(context, 'close');
      },
      
    );
  }
}
