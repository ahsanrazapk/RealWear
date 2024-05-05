import 'package:flutter/material.dart';
import 'package:wfveflutterexample/view/widgets/expansion_tile_card.dart';

class StepModel {
  GlobalKey<ExpansionTileCardState> parent;
  String title;

  String number;

  StepModel({required this.parent, required this.title, required this.number});
}

class StepListModel {
  StepModel parent;
  List<StepModel> child;

  StepListModel({required this.parent, required this.child});

}
