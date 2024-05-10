import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/base/base_widget.dart';
import 'package:wfveflutterexample/view/widgets/expansion_tile_card.dart';
import 'package:wfveflutterexample/view/step_item.dart';

import '../model/step_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  List<StepModel> list = [StepModel(number: '1',parent: GlobalKey<ExpansionTileCardState>(), title:'Step 1', child: [StepModel(number: '1.1',parent: GlobalKey<ExpansionTileCardState>(), title:'Step 1.1')])];


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: list.map((e) => StepItem(stepModel: e, isChild: false,)).toList(),
        ),
      ),
    );
  }
}
