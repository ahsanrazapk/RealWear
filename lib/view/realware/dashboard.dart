import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/services/input_tag.dart';
import 'package:wfveflutterexample/view/widgets/camera/camera_picker.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  bool isParent = true;
  int parentIndex = 0;
  int childIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(
              onItemSelected: (bool isParent, int parentIndex, int? childIndex) {
                setState(() {
                  this.isParent = isParent;
                  this.parentIndex = parentIndex;
                  this.childIndex = childIndex ?? -1;
                });
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: isParent
                  ? [
                      CameraPicker(
                        maximumRecordingDuration: const Duration(seconds: 15),
                        question: '',
                      ),
                      const InputTag()
                    ][childIndex]
                  : Container(),
            )
          ],
        ),
      ),
    );
  }
}

class TabItem {
  final String title;
  final List<TabItem>? children;

  final GlobalKey globalKey;

  TabItem({required this.title, this.children, required this.globalKey});
}

class Sidebar extends StatefulWidget {
  final Function(bool isParent, int parentIndex, int? childIndex) onItemSelected;

  const Sidebar({super.key, required this.onItemSelected});

  @override
  SidebarState createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  final List<TabItem> tabs = [
    TabItem(
      title: '4',
      globalKey: GlobalKey(),
      children: [
        TabItem(
          title: '1',
          globalKey: GlobalKey(),
        ),
        TabItem(
          title: '2',
          globalKey: GlobalKey(),
        ),
        TabItem(
          title: '3',
          globalKey: GlobalKey(),
        ),
      ],
    ),
    TabItem(title: '5', globalKey: GlobalKey(), children: []),
    TabItem(title: '6', globalKey: GlobalKey(), children: []),
    TabItem(
      title: '7',
      globalKey: GlobalKey(),
      children: [
        TabItem(
          title: '1',
          globalKey: GlobalKey(),
        ),
        TabItem(
          title: '2',
          globalKey: GlobalKey(),
        ),
        TabItem(
          title: '3',
          globalKey: GlobalKey(),
        ),
      ],
    ),
    TabItem(title: '8', globalKey: GlobalKey(), children: []),
    TabItem(title: '9', globalKey: GlobalKey(), children: []),
  ];

  int _selectedIndex = 0;

  int _childSelectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, // Sidebar width
      child: Column(
        children: [
          Semantics(
            label: 'hf_no_number:|hf_commands:previous|hf_commands:up|',
            button: true,
            onTap: _previous,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: _previous,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: CustomScrollPhysics(),
              itemCount: tabs.length,
              itemBuilder: (context, index) => _buildTile(tabs[index], index),
            ),
          ),
          Semantics(
            label: 'hf_no_number:|hf_commands:next|hf_commands:down|',
            button: true,
            onTap: _next,
            child: IconButton(
              icon: const Icon(Icons.arrow_downward, color: Colors.white),
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(TabItem tab, int index) {
    bool isSelected = index == _selectedIndex;
    return AnimatedContainer(
      key: tab.globalKey,
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: ColorManager.subStep,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            tab.title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(color: isSelected ? Colors.cyan : Colors.white, fontWeight: FontWeight.w900),
          ),
          if (isSelected && tab.children != null && (tab.children?.isNotEmpty ?? false))
            ...tab.children!.map(
              (e) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  key: e.globalKey,
                  e.title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.displayLarge
                      ?.copyWith(color: tab.children!.indexOf(e) == _childSelectedIndex ? ColorManager.secondary : Colors.white),
                ),
              ),
            )
        ],
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _next() {
    setState(() {
      if (_childSelectedIndex < (tabs[_selectedIndex].children?.length ?? 0) - 1) {
        _childSelectedIndex++;
      } else {
        _childSelectedIndex = -1;
        if (_selectedIndex < tabs.length - 1) {
          _selectedIndex++;
        }
      }
    });

    if ((tabs[_selectedIndex].children?.isNotEmpty ?? false) && _childSelectedIndex != -1) {
      _scrollToElement(tabs[_selectedIndex].children![_childSelectedIndex].globalKey, false);
    } else {
      _scrollToElement(tabs[_selectedIndex].globalKey, false);
    }
    if (_childSelectedIndex != -1) {
      widget.onItemSelected(false, _selectedIndex, _childSelectedIndex);
    } else {
      widget.onItemSelected(true, _selectedIndex, null);
    }

    if (_childSelectedIndex != -1) {
      widget.onItemSelected(false, _selectedIndex, _childSelectedIndex);
    } else {
      widget.onItemSelected(true, _selectedIndex, null);
    }
  }

  void _previous() {
    setState(() {
      if (_childSelectedIndex >= 0) {
        _childSelectedIndex--;
      } else {
        if (_selectedIndex > 0) {
          _selectedIndex--;
          _childSelectedIndex = (tabs[_selectedIndex].children?.length ?? 0) - 1;
        }
      }
    });

    if (_childSelectedIndex >= 0 && (tabs[_selectedIndex].children?.isNotEmpty ?? false)) {
      _scrollToElement(tabs[_selectedIndex].children![_childSelectedIndex].globalKey, true);
    } else {
      _scrollToElement(tabs[_selectedIndex].globalKey, true);
    }

    if (_childSelectedIndex != -1) {
      widget.onItemSelected(false, _selectedIndex, _childSelectedIndex);
    } else {
      widget.onItemSelected(true, _selectedIndex, null);
    }
  }

  void _scrollToElement(GlobalKey globalKey, bool start) {
    final context = globalKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
        alignmentPolicy: start ? ScrollPositionAlignmentPolicy.keepVisibleAtStart : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }
}

class CustomScrollPhysics extends BouncingScrollPhysics {
  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100,
        ratio: 1.1,
      );

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics();
  }
}
