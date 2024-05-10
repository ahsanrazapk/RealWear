import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/base/base_widget.dart';
import 'package:wfveflutterexample/model/step_model.dart';
import 'package:wfveflutterexample/view/input_tag.dart';
import 'package:wfveflutterexample/view/widgets/camera/camera_picker.dart';
import 'package:wfveflutterexample/view/widgets/expansion_tile_card.dart';
import 'package:wfveflutterexample/view/widgets/webview.dart';

List<IconData> icon = [Icons.input, Icons.emergency_recording, Icons.open_in_browser_outlined];

class StepItem extends BaseStateFullWidget {
  final StepModel stepModel;
  final bool isChild;
  StepItem({super.key, required this.stepModel, required this.isChild});

  @override
  State<StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<StepItem> with SingleTickerProviderStateMixin {
  int currentTab = 0;
  late TabController tabController = TabController(length: icon.length, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: ExpansionTileCard(
        baseColor: widget.isChild ? ColorManager.subStep : ColorManager.step,
        expandedColor: widget.isChild ? ColorManager.subStep : ColorManager.step,
        initialElevation: 4.0,
        elevation: 4.0,
        shadowColor: widget.isChild ? ColorManager.subStep : ColorManager.step,
        key: widget.stepModel.parent,
        leading: CircleAvatar(backgroundColor: widget.isChild ? ColorManager.step : ColorManager.subStep, child: Text(widget.stepModel.number)),
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
              decoration: BoxDecoration(color: ColorManager.tagBg, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (currentTab > 0) {
                        --currentTab;
                        tabController.animateTo(currentTab, duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  Expanded(
                      child: TabBar(
                    isScrollable: true,
                    unselectedLabelColor: ColorManager.white,
                    labelColor: ColorManager.secondary,
                    onTap: (tab) {
                      setState(() {
                        currentTab = tab;
                      });
                    },
                    tabs: List.generate(
                        icon.length,
                        (index) => Tab(
                            icon: IconButton(
                                onPressed: () {
                                  currentTab = index;
                                  tabController.animateTo(index, duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
                                  if (index == 0) {
                                    widget.navigator.push(const InputTag());
                                  } else if (index == 1) {
                                    widget.navigator.push(const CameraPicker(
                                      maximumRecordingDuration: Duration(seconds: 15),
                                    ));
                                  } else if (index == 2) {
                                    widget.navigator.push(const WebView());
                                  }
                                },
                                icon: Icon(icon[index])))),
                    padding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabAlignment: TabAlignment.start,
                    controller: tabController,
                  )),
                  IconButton(
                    onPressed: () {
                      if (currentTab < tabController.length - 1) {
                        ++currentTab;
                        tabController.animateTo(currentTab, duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ),
          if (widget.stepModel.child != null)
            ...(widget.stepModel.child ?? []).map((e) => StepItem(
                  stepModel: e,
                  isChild: true,
                ))
        ],
      ),
    );
  }
}
