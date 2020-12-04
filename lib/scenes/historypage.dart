import 'package:flutter/material.dart';
import 'package:tProject/globals.dart';
import 'package:tProject/widgets/branddivider.dart';
import 'package:tProject/widgets/historytile.dart';

import '../brand-colors.dart';

class HistoryPage extends StatefulWidget {
  @override
  static const String id = "history";
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  initState()  {
    
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histaurique'),
        backgroundColor: BrandColors.colorPrimary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(0),
        itemBuilder: (context, index) {
          return HistoryTile(
            history:
                currentUserInfo.trips[index]
          );
        },
        separatorBuilder: (BuildContext context, int index) => BrandDivider(),
        itemCount:
            currentUserInfo.trips.length,
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
      ),
    );
  }
}
