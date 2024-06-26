import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/model/stepmodel.dart';
import 'package:wfveflutterexample/view/widgets/expansion_tile_card.dart';

class SubStepItem extends StatefulWidget {
  final StepModel stepModel;
  SubStepItem({super.key, required this.stepModel});

  @override
  State<SubStepItem> createState() => _SubStepItemState();
}

class _SubStepItemState extends State<SubStepItem> with SingleTickerProviderStateMixin {
  int currentTab = -1;
  late TabController tabController = TabController(length: 10, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: ExpansionTileCard(
        baseColor: ColorManager.subStep,
        expandedColor: ColorManager.subStep,
        initialElevation: 4.0,
        elevation: 4.0,
        shadowColor: ColorManager.subStep,
        key: widget.stepModel.parent,
        leading: CircleAvatar(backgroundColor: ColorManager.step, child: Text(widget.stepModel.number)),
        title: Text(widget.stepModel.title),
        subtitle: const Text('Running'),
        children: <Widget>[
          const Divider(
            thickness: 1.0,
            height: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: context.width,
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(color: ColorManager.tagBg, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if(currentTab>0){
                        currentTab--;
                        tabController.animateTo(currentTab, duration: Duration(milliseconds: 250),curve: Curves.easeIn );
                      }
                    },
                    icon: Icon(Icons.arrow_back_ios),
                  ),
                  Expanded(
                      child: TabBar(
                        isScrollable: true,
                    unselectedLabelColor: ColorManager.white,
                    labelColor: ColorManager.secondary,
                    onTap: (tab){
                          setState(() {
                            currentTab = tab;
                          });
                    },
                    tabs: List.generate(
                        10,
                        (index) => const Tab(
                              icon: Icon(Icons.input)
                            )),
                    padding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabAlignment: TabAlignment.start,
                    controller: tabController,
                  )),
                  IconButton(
                    onPressed: () {
                      if(currentTab < tabController.length-1){
                        currentTab++;
                        tabController.animateTo(currentTab, duration: Duration(milliseconds: 250),curve: Curves.easeIn );
                      }
                    },
                    icon: Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
