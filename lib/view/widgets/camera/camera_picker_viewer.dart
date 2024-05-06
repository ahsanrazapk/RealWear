import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'camera_picker.dart';

enum CameraPickerViewType { image, video }

typedef EntitySaveCallback = FutureOr<dynamic> Function({
  BuildContext context,
  CameraPickerViewType viewType,
  File file,
});

class CameraPickerViewer extends StatefulWidget {
  const CameraPickerViewer({
    Key? key,
     this.pickerState,
    required this.pickerType,
    required this.previewXFile,
    this.shouldDeletePreviewFile = false,
  }) : super(key: key);

  final CameraPickerState? pickerState;
  final CameraPickerViewType pickerType;
  final File previewXFile;
  final bool shouldDeletePreviewFile;
  static Future<dynamic> pushToViewer(
    BuildContext context, {
     CameraPickerState? pickerState,
    required CameraPickerViewType pickerType,
    required File previewXFile,
    bool shouldDeletePreviewFile = false,
  }) {
    return Navigator.of(context).push<dynamic>(
      PageRouteBuilder<dynamic>(
        pageBuilder: (_, __, ___) => CameraPickerViewer(
          pickerState: pickerState,
          pickerType: pickerType,
          previewXFile: previewXFile,
          shouldDeletePreviewFile: shouldDeletePreviewFile,
        ),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  _CameraPickerViewerState createState() => _CameraPickerViewerState();
}

class _CameraPickerViewerState extends State<CameraPickerViewer> {
  VideoPlayerController? videoController;
  bool hasLoaded = false;
  bool hasErrorWhenInitializing = false;
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  bool get isControllerPlaying => (videoController?.value.isPlaying ?? false);
  CameraPickerState? get pickerState => widget.pickerState;
  CameraPickerViewType get pickerType => widget.pickerType;
  File get previewFile => widget.previewXFile;
  bool get shouldDeletePreviewFile => widget.shouldDeletePreviewFile;

  @override
  void initState() {
    hasLoaded = pickerType == CameraPickerViewType.image;
    if (pickerType == CameraPickerViewType.video) {
      videoController = VideoPlayerController.file(previewFile)
        ..initialize().then((value) {
          setState(() {
            videoController?.setVolume(0.0);
            videoController?.addListener(videoPlayerListener);
            hasLoaded = true;
          });
        });
    }
    super.initState();
  }

  @override
  void dispose() {
    videoController?.removeListener(videoPlayerListener);
    videoController?.pause();
    videoController?.dispose();
    super.dispose();
  }

  void videoPlayerListener() {
    if (isControllerPlaying != isPlaying.value) {
      isPlaying.value = isControllerPlaying;
    }
  }

  Future<void> playButtonCallback() async {
    if (isPlaying.value) {
      videoController?.pause();
    } else {
      if (videoController?.value.duration == videoController?.value.position) {
        videoController
          ?..seekTo(Duration.zero)
          ..play();
      } else {
        videoController?.play();
      }
    }
  }


  Widget get previewRetryButton {
    return InkWell(
      onTap: () {
        if (previewFile.existsSync()) {
          previewFile.delete();
        }
        Navigator.of(context).pop(true);
      },
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: const Text(
          "Retry",
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget get previewBackButton {
    return Semantics(
      label: 'hf_no_number:|hf_commands:back|',
      button: true,
      onTap: (){
        if (previewFile.existsSync()) {
          previewFile.delete();
        }
        Navigator.of(context).pop(false);
      },
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(999999)),
        onTap: () {
          if (previewFile.existsSync()) {
            previewFile.delete();
          }
          Navigator.of(context).pop(false);
        },
        child: Container(
          margin: const EdgeInsets.all(10.0),
          width: 27,
          height: 27,
          child: const Center(
            child: Icon(
              Icons.clear,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget get previewConfirmButton {
    return Semantics(
      label: 'hf_no_number:|hf_commands:save|',
      button: true,
      onTap: (){
        if (previewFile.existsSync()) {
          previewFile.delete();
        }
        Navigator.of(context).pop(false);
      },
      child: MaterialButton(
        minWidth: 40.0,
        height: 40.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        onPressed: (){
          Navigator.of(context).pop(false);
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: const Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget get playControlButton {
    return ValueListenableBuilder<bool>(
      valueListenable: isPlaying,
      builder: (_, bool value, Widget? child) => Semantics(
        label: value ? 'hf_no_number:|hf_commands:pause|':'hf_no_number:|hf_commands:play|',
        button: true,
        onTap: playButtonCallback,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: value ? playButtonCallback : null,
          child: Center(
            child: AnimatedOpacity(
              duration: kThemeAnimationDuration,
              opacity: value ? 0.0 : 1.0,
              child: GestureDetector(
                onTap: playButtonCallback,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: <BoxShadow>[BoxShadow(color: Colors.black12)],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value ? Icons.pause_circle_outline : Icons.play_circle_filled,
                    size: 70.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget get viewerActions {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          color: Colors.black.withOpacity(0.2),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      previewRetryButton,
                      previewBackButton,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.2),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  switchSoundButton(videoController?.value.volume),
                  previewConfirmButton,
                  Opacity(opacity: 0,child: downloadButton())
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget switchSoundButton(vol) {
    IconData? icon;
    if (vol == 0.0) {
      icon = Icons.volume_mute;
    } else if (vol == 1.0) {
      icon = Icons.volume_up;
    }
    return IconButton(
      onPressed: () {
        (videoController?.value.volume ?? 0.0) > 0.0
            ? videoController?.setVolume(0.0)
            : videoController?.setVolume(1.0);
        setState(() {});
      },
      icon: Icon(
        icon,
        size: 28,
        color: Colors.white,
      ),
    );
  }

  Widget downloadButton() {
    return const IconButton(
      onPressed: null,
      icon: Icon(
        Icons.download_rounded,
        size: 28,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hasErrorWhenInitializing) {
      return const Center(
        child: Text(
          'Fail to load',
        ),
      );
    }
    if (!hasLoaded) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          // Place the specific widget according to the view type.
          if (pickerType == CameraPickerViewType.image)
            Positioned.fill(child: Image.file(previewFile))
          else if (pickerType == CameraPickerViewType.video)
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: videoController?.value.aspectRatio ?? 0,
                  child: VideoPlayer(videoController!),
                ),
              ),
            ),
          // Place the button before the actions to ensure it's not blocking.
          if (pickerType == CameraPickerViewType.video) playControlButton,
          viewerActions,
        ],
      ),
    );
  }
}
