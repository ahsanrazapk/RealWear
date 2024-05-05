import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/model/stepmodel.dart';
import 'package:wfveflutterexample/view/widgets/expansion_tile_card.dart';
import 'package:wfveflutterexample/view/sub_step_item.dart';

class StepItem extends StatefulWidget {

 final StepListModel stepListModel;
   const StepItem({super.key, required this.stepListModel});

  @override
  State<StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<StepItem> with SingleTickerProviderStateMixin {
  int currentTab = -1;
  late TabController tabController = TabController(length: 10, vsync: this);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: ExpansionTileCard(
        baseColor: ColorManager.step,
        expandedColor: ColorManager.step,
        initialElevation: 4.0,
        elevation: 4.0,
        shadowColor: ColorManager.step,
        key: widget.stepListModel.parent.parent,
        leading:   CircleAvatar(backgroundColor: ColorManager.subStep,child: Text(widget.stepListModel.parent.number)),
        title:   Text(widget.stepListModel.parent.title),
        subtitle: const Text('Running'),
        children: <Widget>[
          const Divider(
            thickness: 1.0,
            height: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(width: context.width,height: 55,decoration: BoxDecoration(color: ColorManager.tagBg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back_ios),),
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
                IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward_ios),),

              ],
            ),
            ),
          ),
          ...widget.stepListModel.child.map((e) => SubStepItem(stepModel: e))

        ],
      ),
    );
  }
}
