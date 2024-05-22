import 'dart:async';
import  'dart:io' if (dart.library.html) 'dart:html';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:wfveflutterexample/common/verification_type.dart';
import 'package:wfveflutterexample/main.dart';
import 'camera_picker_viewer.dart';
import 'circular_progress_bar.dart';
import 'exposure_point_widget.dart';
import 'package:image/image.dart' as img;

const Color _lockedColor = Colors.amber;
const Duration _kRouteDuration = Duration(milliseconds: 300);

class CameraPicker extends StatefulWidget {
  const CameraPicker({
    super.key,
    this.enableRecording = true,
    this.maximumRecordingDuration = const Duration(seconds: 15),
    this.resolutionPreset = ResolutionPreset.medium,
  });
  final bool enableRecording;
  final Duration maximumRecordingDuration;
  final ResolutionPreset resolutionPreset;

  @override
  CameraPickerState createState() => CameraPickerState();
}

class CameraPickerState extends State<CameraPicker> with WidgetsBindingObserver {
  final Duration recordDetectDuration = const Duration(milliseconds: 200);
  final ValueNotifier<Offset?> _lastExposurePoint = ValueNotifier<Offset?>(null);
  Offset? _lastShootingButtonPressedPosition;
  final ValueNotifier<ExposureMode> _exposureMode = ValueNotifier<ExposureMode>(ExposureMode.auto);
  final ValueNotifier<bool> _isExposureModeDisplays = ValueNotifier<bool>(false);
  final ValueNotifier<CameraController?> _controllerNotifier = ValueNotifier<CameraController?>(null);

  CameraController? get controller => _controllerNotifier.value;
  List<CameraDescription>? cameras;
  final ValueNotifier<double> _currentExposureOffset = ValueNotifier<double>(0);
  int cameraQuarterTurns = 4;
  final bool _enableSetExposure = true;
  final bool _enableExposureControlOnPoint = true;
  final bool _enablePinchToZoom = true;
  final bool _enablePullToZoomInRecord = true;
  final bool _shouldDeletePreviewFile = false;
  double _maxAvailableExposureOffset = 0;
  double _minAvailableExposureOffset = 0;
  double _maxAvailableZoom = 1;
  double _minAvailableZoom = 1;
  int _pointers = 0;
  double _currentZoom = 1;
  double _baseZoom = 1;
  int currentCameraIndex = 0;
  bool isShootingButtonAnimate = false;
  Timer? _exposurePointDisplayTimer;
  Timer? _exposureModeDisplayTimer;
  Timer? _recordCountdownTimer;

  bool get enableRecording => widget.enableRecording;

  bool get enableAudio => enableRecording;

  bool get shouldPrepareForVideoRecording => enableRecording && enableAudio && platformType.isIOS;

  bool get enableSetExposure => _enableSetExposure;

  bool get enableExposureControlOnPoint => _enableExposureControlOnPoint;

  bool get enablePinchToZoom => _enablePinchToZoom;

  bool get enablePullToZoomInRecord => _enablePullToZoomInRecord;

  bool get shouldDeletePreviewFile => _shouldDeletePreviewFile;

  Duration get maximumRecordingDuration => widget.maximumRecordingDuration;

  CameraDescription? get currentCamera => cameras?.elementAt(currentCameraIndex);
  bool _isPreparedForIOSRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (platformType.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: <SystemUiOverlay>[]);
    }
    if (mounted) {
      initCameras();
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    if (platformType.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    _controllerNotifier.dispose();
    _currentExposureOffset.dispose();
    _lastExposurePoint.dispose();
    _exposureMode.dispose();
    _isExposureModeDisplays.dispose();
    _exposurePointDisplayTimer?.cancel();
    _exposureModeDisplayTimer?.cancel();
    _recordCountdownTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controllerNotifier.value == null || !(controller?.value.isInitialized ?? false)) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCameras(currentCamera);
    }
  }

  int _previewQuarterTurns(DeviceOrientation orientation) {
    if (orientation == DeviceOrientation.landscapeRight) {
      cameraQuarterTurns = orientation.index + 1;
      return cameraQuarterTurns;
    } else if (orientation == DeviceOrientation.landscapeLeft) {
      cameraQuarterTurns = platformType == PlatformType.realwear ? orientation.index : orientation.index - 1;
      return cameraQuarterTurns;
    }
    cameraQuarterTurns = orientation.index;
    return cameraQuarterTurns;
  }

  _PreviewScaleType _effectiveScaleType(BoxConstraints constraints) {
    final Size? _size = controller?.value.previewSize;
    final Size _scaledSize = (_size ?? Size.zero) * constraints.maxWidth * context.scale / (_size?.height ?? 0.0);
    if (_scaledSize.width > constraints.maxHeight * context.scale) {
      return _PreviewScaleType.width;
    } else if (_scaledSize.width < constraints.maxHeight * context.scale) {
      return _PreviewScaleType.height;
    } else {
      return _PreviewScaleType.none;
    }
  }

  int uvPixelIndex(int x, int y, int width) {
    int uvWidth = width ~/ 2;
    int uvHeight = y ~/ 2;
    return uvHeight * uvWidth + (x ~/ 2);
  }

  Uint8List? convertYUV420toImageColor(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;
      final img.Image image = img.Image(width: width, height: height);

      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex = uvPixelIndex(x, y, width);
          final int index = y * width + x;
          final Y = cameraImage.planes[0].bytes[index];
          final U = cameraImage.planes[1].bytes[uvIndex] - 128;
          final V = cameraImage.planes[2].bytes[uvIndex] - 128;

          int r = (Y + V * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (Y - U * 46549 / 131072 + 44 - V * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (Y + U * 1814 / 1024 - 227).round().clamp(0, 255);

          image.setPixelRgba(x, y, r, g, b, 225);
        }
      }
      final Uint8List pngBytes = img.encodePng(image);
      return pngBytes;
    } catch (e) {
      return null;
    }
  }

  void initCameras([CameraDescription? cameraDescription]) {
    final CameraController? _c = _controllerNotifier.value;



    setState(() {
      _maxAvailableZoom = 1;
      _minAvailableZoom = 1;
      _currentZoom = 1;
      _baseZoom = 1;
      _controllerNotifier.value = null;
      _exposureModeDisplayTimer?.cancel();
      _exposurePointDisplayTimer?.cancel();
      _lastExposurePoint.value = null;
      if (_currentExposureOffset.value != 0) {
        _currentExposureOffset.value = 0;
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _c?.dispose();
      if (cameraDescription == null) {
        cameras = await availableCameras();
      }
      if (cameraDescription == null && (cameras?.isEmpty ?? true)) {
        throw CameraException(
          'No CameraDescription found.',
          'No cameras are available in the controller.',
        );
      }

      _controllerNotifier.value = CameraController(
        cameraDescription ?? cameras?[0] ?? (await availableCameras())[0],
        widget.resolutionPreset,
        enableAudio: enableAudio,
        imageFormatGroup: platformType.isIOS ? ImageFormatGroup.yuv420 : ImageFormatGroup.jpeg,
      )..addListener(() {
/*
          if (controller.value.hasError) {
            throw CameraException(
              'CameraController exception',
              controller.value.errorDescription,
            );
          }
*/
        });

      try {
        await controller?.initialize();
        Future.wait<void>(<Future<dynamic>>[
          (() async => _maxAvailableExposureOffset = await controller?.getMaxExposureOffset() ?? 0.0)(),
          (() async => _minAvailableExposureOffset = await controller?.getMinExposureOffset() ?? 0.0)(),
          (() async => _maxAvailableZoom = await controller?.getMaxZoomLevel() ?? 0.0)(),
          (() async => _minAvailableZoom = await controller?.getMinZoomLevel() ?? 0.0)(),
        ]);
      } catch (_) {
        rethrow;
      } finally {
        setState(() {});
      }
    });

  }

  camStream(){
    controller?.startImageStream((image) {
     Uint8List? uint8list = convertYUV420toImageColor(image);
    });
  }

  void switchCameras() {
    ++currentCameraIndex;
    if (currentCameraIndex == (cameras?.length ?? 0)) {
      currentCameraIndex = 0;
    }
    initCameras(currentCamera);
  }

  Future<void> switchFlashesMode() async {
    switch (controller?.value.flashMode ?? FlashMode.auto) {
      case FlashMode.off:
        await controller?.setFlashMode(FlashMode.auto);
        break;
      case FlashMode.auto:
        await controller?.setFlashMode(FlashMode.torch);
        break;
      case FlashMode.always:
      case FlashMode.torch:
        await controller?.setFlashMode(FlashMode.off);
        break;
    }
  }

  Future<void> zoom(double scale) async {
    final double _zoom = (_baseZoom * scale).clamp(_minAvailableZoom, _maxAvailableZoom).toDouble();
    if (_zoom == _currentZoom) {
      return;
    }
    _currentZoom = _zoom;

    await controller?.setZoomLevel(_currentZoom);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_pointers != 2) {
      return;
    }

    zoom(details.scale);
  }

  void _restartPointDisplayTimer() {
    _exposurePointDisplayTimer?.cancel();
    _exposurePointDisplayTimer = Timer(const Duration(seconds: 5), () {
      _lastExposurePoint.value = null;
    });
  }

  void _restartModeDisplayTimer() {
    _exposureModeDisplayTimer?.cancel();
    _exposureModeDisplayTimer = Timer(const Duration(seconds: 2), () {
      _isExposureModeDisplays.value = false;
    });
  }

  void switchExposureMode() {
    if (_exposureMode.value == ExposureMode.auto) {
      _exposureMode.value = ExposureMode.locked;
    } else {
      _exposureMode.value = ExposureMode.auto;
    }
    _exposurePointDisplayTimer?.cancel();
    if (_exposureMode.value == ExposureMode.auto) {
      _exposurePointDisplayTimer = Timer(const Duration(seconds: 5), () {
        _lastExposurePoint.value = null;
      });
    }
    controller?.setExposureMode(_exposureMode.value);
    _restartModeDisplayTimer();
  }

  Future<void> setExposureAndFocusPoint(
    TapUpDetails details,
    BoxConstraints constraints,
  ) async {
    _isExposureModeDisplays.value = false;
    if (details.globalPosition.dy < constraints.maxHeight / 12 || details.globalPosition.dy > constraints.maxHeight / 12 * 11) {
      return;
    }

    _lastExposurePoint.value = Offset(
      details.globalPosition.dx,
      details.globalPosition.dy,
    );
    _restartPointDisplayTimer();
    _currentExposureOffset.value = 0;
    //await controller.setExposureOffset(0);
    if (_exposureMode.value == ExposureMode.locked) {
      await controller?.setExposureMode(ExposureMode.auto);
      _exposureMode.value = ExposureMode.auto;
    }
    controller?.setExposurePoint(
      _lastExposurePoint.value?.scale(
        1 / constraints.maxWidth,
        1 / constraints.maxHeight,
      ),
    );
    if (controller?.value.focusPointSupported == true) {
      controller?.setFocusPoint(
        _lastExposurePoint.value?.scale(
          1 / constraints.maxWidth,
          1 / constraints.maxHeight,
        ),
      );
    }
  }

  void updateExposureOffset(double value) {
    if (value == _currentExposureOffset.value) {
      return;
    }
    _currentExposureOffset.value = value;
    controller?.setExposureOffset(value);
    if (!_isExposureModeDisplays.value) {
      _isExposureModeDisplays.value = true;
    }
    _restartModeDisplayTimer();
    _restartPointDisplayTimer();
  }

  void onShootingButtonMove(
    PointerMoveEvent event,
    BoxConstraints constraints,
  ) {
    _lastShootingButtonPressedPosition ??= event.position;
    if (controller?.value.isRecordingVideo ?? false) {
      final Offset _offset = event.position - (_lastShootingButtonPressedPosition ?? Offset.zero);
      final double _scale = _offset.dy / constraints.maxHeight * -14 + 1;
      zoom(_scale);
    }
  }

  Future<void> takePicture() async {
    if (controller!.value.isInitialized && !controller!.value.isTakingPicture) {
      controller?.takePicture().then((value) async {
       /* final dynamic entity = await CameraPickerViewer.pushToViewer(
          context,
          pickerState: this,
          pickerType: CameraPickerViewType.image,
          previewXFile: File((await controller!.takePicture()).path),
          shouldDeletePreviewFile: shouldDeletePreviewFile,
          turns: cameraQuarterTurns,
        );*/
      }).catchError((Object e) {
        initCameras();
        throw e;
      });
    }
  }

  void recordDetection(BoxConstraints constraints) {
    startRecordingVideo(constraints);

    setState(() {
      isShootingButtonAnimate = true;
    });
  }

  void recordDetectionCancel(BoxConstraints constraints) {
    if (isShootingButtonAnimate) {
      setState(() {
        isShootingButtonAnimate = false;
      });
    }
    if (controller?.value.isRecordingVideo ?? true) {
      setState(() {
        _lastShootingButtonPressedPosition = null;

        stopRecordingVideo();
      });
    }
  }

  Future<void> startRecordingVideo(BoxConstraints constraints) async {
    if (!(controller?.value.isRecordingVideo ?? false)) {
      if (!_isPreparedForIOSRecording) {
        await controller?.prepareForVideoRecording();
        _isPreparedForIOSRecording = true;
      }
      controller?.startVideoRecording().then((dynamic _) {
        setState(() {});
        _recordCountdownTimer = Timer(maximumRecordingDuration, () {
          stopRecordingVideo();
        });
      }).catchError((Object e) {
        if (controller?.value.isRecordingVideo ?? true) {
          controller?.stopVideoRecording().catchError((onError) {
            stopRecordingVideo();
            throw onError;
          });
        }
        throw e;
      });
    }
  }

  Future<void> stopRecordingVideo() async {
    void _handleError() {
      _recordCountdownTimer?.cancel();
      isShootingButtonAnimate = false;
      durationNotifier.value = Duration.zero;
      setState(() {});
    }

    if (controller?.value.isRecordingVideo ?? false) {
      controller?.stopVideoRecording().then((XFile xFile) async {
        controller?.setFlashMode(FlashMode.auto);
        final nav = Navigator.of(context);
  /*      final dynamic entity = await CameraPickerViewer.pushToViewer(context,
            pickerState: this,
            pickerType: CameraPickerViewType.video,
            previewXFile: File(xFile.path),
            shouldDeletePreviewFile: shouldDeletePreviewFile,
            turns: cameraQuarterTurns);*/
      }).catchError((Object e) {
        initCameras();
        _handleError();
        throw e;
      }).whenComplete(() {
        isShootingButtonAnimate = false;
        setState(() {});
      });
      return;
    }
    _handleError();
  }

  Widget settingsAction(BoxConstraints constraints) {
    return _initializeWrapper(
      builder: (CameraValue v, __) {
        return SafeArea(
          child: Container(
            color: (controller?.value.isRecordingVideo ?? false) ? Colors.transparent : Colors.black.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                shootingButton(constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get switchCamerasButton {
    return IconButton(
      onPressed: switchCameras,
      icon: const Icon(Icons.flip_camera_ios_outlined, size: 28, color: Colors.white),
    );
  }

  Widget switchFlashesButton(CameraValue value) {
    IconData icon;
    switch (value.flashMode) {
      case FlashMode.off:
        icon = Icons.flash_off;
        break;
      case FlashMode.auto:
        icon = Icons.flash_auto;
        break;
      case FlashMode.always:
      case FlashMode.torch:
        icon = Icons.flash_on;
        break;
    }
    return IconButton(
      onPressed: switchFlashesMode,
      icon: Icon(
        icon,
        size: 28,
        color: Colors.white,
      ),
    );
  }

/*
  Widget tipsTextWidget(CameraController controller) {
    return AnimatedOpacity(
      duration: recordDetectDuration,
      opacity: controller.value.isRecordingVideo == true ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 5.0,
        ),
        child: Text(
          Locales.string(context,question),
          style:  GoogleFonts.mulish(fontSize: 18.0, color: Colors.white),
        ),
      ),
    );
  }
*/

  Widget shootingActions(
    BuildContext context,
    CameraController controller,
    BoxConstraints constraints,
  ) {
    return SafeArea(
      child: Container(
        color: controller.value.isRecordingVideo ? Colors.transparent : Colors.black.withOpacity(0.2),
        child: Row(
          children: <Widget>[backButton(context, constraints)],
        ),
      ),
    );
  }

  Widget backButton(BuildContext context, BoxConstraints constraints) {
    return Semantics(
      label: 'hf_no_number:|hf_commands:back',
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(999999)),
        onTap: Navigator.of(context).pop,
        child: Container(
          margin: const EdgeInsets.all(10.0),
          width: 27,
          height: 27,
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget shootingButton(BoxConstraints constraints) {
    const Size outerSize = Size.square(115);
    const Size innerSize = Size.square(82);
    return Semantics(
      label: isShootingButtonAnimate
          ? 'hf_no_number:|hf_commands:stop|hf_commands:stop recording|'
          : 'hf_no_number:|hf_commands:record|hf_commands:record video|',
      onTap: () => isShootingButtonAnimate ? recordDetectionCancel(constraints) : recordDetection(constraints),
      button: true,
      /* customSemanticsActions: {
        const CustomSemanticsAction(label: 'hf_no_number:|hf_commands:record|hf_commands:record video|'): () {
          if (!isShootingButtonAnimate) {
            recordDetection(constraints);
          }
        },
        const CustomSemanticsAction(label: 'hf_no_number:|hf_commands:capture|hf_commands:capture image|'): () {
          if (!isShootingButtonAnimate) {
            takePicture();
          }
        },
        const CustomSemanticsAction(label: 'hf_no_number:|hf_commands:stop|hf_commands:stop recording|'): () {
          if (isShootingButtonAnimate) {
            recordDetectionCancel(constraints);
          }
        }
      },*/
      child: Listener(
        behavior: HitTestBehavior.opaque,
        /*  onPointerUp: enableRecording
            ? (PointerUpEvent event) {
          recordDetectionCancel(event, constraints);
        }
            : null,*/
        onPointerMove: enablePullToZoomInRecord ? (PointerMoveEvent e) => onShootingButtonMove(e, constraints) : null,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(999999)),
          onTap: () => isShootingButtonAnimate ? recordDetectionCancel(constraints) : recordDetection(constraints),
          /*  onLongPress: enableRecording
              ? () {
                  if (!isShootingButtonAnimate) {
                    recordDetection(constraints);
                  }
                }
              : null,*/
          child: SizedBox.fromSize(
            size: outerSize,
            child: Stack(
              children: <Widget>[
                Center(
                  child: AnimatedContainer(
                    duration: kThemeChangeDuration,
                    width: isShootingButtonAnimate ? outerSize.width : innerSize.width,
                    height: isShootingButtonAnimate ? outerSize.height : innerSize.height,
                    padding: EdgeInsets.all(isShootingButtonAnimate ? 41 : 11),
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                _initializeWrapper(
                  isInitialized: () => (controller?.value.isRecordingVideo ?? false) && isShootingButtonAnimate,
                  builder: (_, __) => CircleProgressBar(
                    duration: maximumRecordingDuration,
                    outerRadius: outerSize.width,
                    ringsWidth: 2.0,
                    ringsColor: ColorManager.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exposureSlider(
    ExposureMode mode,
    double size,
    double height,
    double gap,
  ) {
    // final bool isLocked = mode == ExposureMode.locked;
    const Color color = _lockedColor;

    Widget _line() {
      return ValueListenableBuilder<bool>(
        valueListenable: _isExposureModeDisplays,
        builder: (_, bool value, Widget? child) => AnimatedOpacity(
          duration: _kRouteDuration,
          opacity: value ? 1 : 0,
          child: child,
        ),
        child: Center(child: Container(width: 1, color: color)),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: _currentExposureOffset,
      builder: (_, double exposure, __) {
        final double _effectiveTop = (size + gap) +
            (_minAvailableExposureOffset.abs() - exposure) * (height - size * 3) / (_maxAvailableExposureOffset - _minAvailableExposureOffset);
        final double _effectiveBottom = height - _effectiveTop - size;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              top: _effectiveTop + gap,
              child: _line(),
            ),
            Positioned.fill(
              bottom: _effectiveBottom + gap,
              child: _line(),
            ),
            Positioned(
              top: (_minAvailableExposureOffset.abs() - exposure) * (height - size * 3) / (_maxAvailableExposureOffset - _minAvailableExposureOffset),
              child: Transform.rotate(
                angle: exposure,
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: size,
                  color: color,
                ),
              ),
            ),
            Positioned.fill(
              top: -10,
              bottom: -10,
              child: RotatedBox(
                quarterTurns: 3,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Opacity(
                    opacity: 0,
                    child: Slider(
                      value: exposure,
                      min: _minAvailableExposureOffset,
                      max: _maxAvailableExposureOffset,
                      onChanged: updateExposureOffset,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _focusingAreaWidget(BoxConstraints constraints) {
    Widget _buildControl(double size, double height) {
      const double _verticalGap = 3;
      return ValueListenableBuilder<ExposureMode>(
        valueListenable: _exposureMode,
        builder: (_, ExposureMode mode, __) {
          final bool isLocked = mode == ExposureMode.locked;
          return Column(
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: _isExposureModeDisplays,
                builder: (_, bool value, Widget? child) => AnimatedOpacity(
                  duration: _kRouteDuration,
                  opacity: value ? 1 : 0,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: switchExposureMode,
                  child: SizedBox.fromSize(
                    size: Size.square(size),
                    child: Icon(
                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: size,
                      color: _lockedColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _verticalGap),
              Expanded(
                child: _exposureSlider(mode, size, height, _verticalGap),
              ),
              const SizedBox(height: _verticalGap),
              SizedBox.fromSize(size: Size.square(size)),
            ],
          );
        },
      );
    }

    Widget _buildFromPoint(Offset point) {
      const double _controllerWidth = 20;
      final double _pointWidth = constraints.maxWidth / 5;
      final double _exposureControlWidth = enableExposureControlOnPoint ? _controllerWidth : 0;
      final double _width = _pointWidth + _exposureControlWidth + 2;

      final bool _shouldReverseLayout = point.dx > constraints.maxWidth / 4 * 3;

      final double _effectiveLeft = math.min(
        constraints.maxWidth - _width,
        math.max(0, point.dx - _width / 2),
      );
      final double _effectiveTop = math.min(
        constraints.maxHeight - _pointWidth * 3,
        math.max(0, point.dy - _pointWidth * 3 / 2),
      );

      return Positioned(
        left: _effectiveLeft,
        top: _effectiveTop,
        width: _width,
        height: _pointWidth * 3,
        child: Row(
          textDirection: _shouldReverseLayout ? TextDirection.rtl : TextDirection.ltr,
          children: <Widget>[
            ExposurePointWidget(
              key: ValueKey<int>(DateTime.now().millisecondsSinceEpoch),
              size: _pointWidth,
              color: _lockedColor,
            ),
            if (enableExposureControlOnPoint) const SizedBox(width: 2),
            if (enableExposureControlOnPoint)
              SizedBox.fromSize(
                size: Size(_exposureControlWidth, _pointWidth * 3),
                child: _buildControl(_controllerWidth, _pointWidth * 3),
              ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<Offset?>(
      valueListenable: _lastExposurePoint,
      builder: (_, Offset? point, __) {
        if (point == null) {
          return const SizedBox.shrink();
        }
        return _buildFromPoint(point);
      },
    );
  }

  Widget _exposureDetectorWidget(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Positioned.fill(
      child: GestureDetector(
        onTapUp: (TapUpDetails d) => setExposureAndFocusPoint(d, constraints),
        behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _cameraPreview(
    BuildContext context, {
    required DeviceOrientation orientation,
    required BoxConstraints constraints,
  }) {
    Widget _preview = Listener(
      onPointerDown: (_) => _pointers++,
      onPointerUp: (_) => _pointers--,
      child: GestureDetector(
        onScaleStart: enablePinchToZoom ? _handleScaleStart : null,
        onScaleUpdate: enablePinchToZoom ? _handleScaleUpdate : null,
        onDoubleTap: (cameras?.length ?? 0) > 1 ? switchCameras : null,
        child: CameraPreview(controller!),
      ),
    );

    final _PreviewScaleType scale = _effectiveScaleType(constraints);
    if (scale == _PreviewScaleType.none) {
      return _preview;
    }

    double _width;
    double _height;
    switch (scale) {
      case _PreviewScaleType.width:
        _width = constraints.maxWidth;
        if (constraints.maxWidth <= constraints.maxHeight) {
          _height = constraints.maxWidth * (controller?.value.aspectRatio ?? 0.0);
        } else {
          _height = constraints.maxWidth / (controller?.value.aspectRatio ?? 0.0);
        }
        break;
      case _PreviewScaleType.height:
        _width = constraints.maxHeight / (controller?.value.aspectRatio ?? 0.0);
        _height = constraints.maxHeight;
        break;
      default:
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;
        break;
    }
    final double _offsetHorizontal = (_width - constraints.maxWidth).abs() / -2;
    final double _offsetVertical = (_height - constraints.maxHeight).abs() / -2;
    _preview = Stack(
      children: <Widget>[
        Positioned(
          left: _offsetHorizontal,
          right: _offsetHorizontal,
          top: _offsetVertical,
          bottom: _offsetVertical,
          child: _preview,
        ),
      ],
    );
    return _preview;
  }

  Widget _initializeWrapper({
    required Widget Function(CameraValue, Widget?) builder,
    bool Function()? isInitialized,
    Widget? child,
  }) {
    return ValueListenableBuilder<CameraController?>(
      valueListenable: _controllerNotifier,
      builder: (_, CameraController? controller, __) {
        if (controller != null) {
          return ValueListenableBuilder<CameraValue>(
            valueListenable: controller,
            builder: (_, CameraValue value, Widget? w) {
              return isInitialized?.call() ?? value.isInitialized ? builder(value, w) : const SizedBox.shrink();
            },
            child: child,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _cameraBuilder({
    required BuildContext context,
    required CameraValue value,
    required BoxConstraints constraints,
  }) {
    return AspectRatio(
      aspectRatio: (controller?.value.aspectRatio ?? 0.0),
      child: RepaintBoundary(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _cameraPreview(
                context,
                orientation: value.deviceOrientation,
                constraints: constraints,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentBuilder(BoxConstraints constraints) {
    return ValueListenableBuilder<CameraController?>(
        valueListenable: _controllerNotifier,
        builder: (
          BuildContext context,
          CameraController? controller,
          _,
        ) {
          if (controller != null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                shootingActions(context, controller, constraints),
                // const Spacer(),
                settingsAction(constraints),
              ],
            );
          }

          return const SizedBox.shrink();
        });
  }

  @override
  Widget build(BuildContext context) {
    return _initializeWrapper(builder: (CameraValue value, __) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Material(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (BuildContext c, BoxConstraints constraints) {
              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: <Widget>[
                  RotatedBox(
                    quarterTurns: _previewQuarterTurns(value.deviceOrientation),
                    child: Builder(
                      builder: (con) {
                        if (value.isInitialized) {
                          return _cameraBuilder(
                            context: c,
                            value: value,
                            constraints: constraints,
                          );
                        }
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                  if (enableSetExposure) _exposureDetectorWidget(c, constraints),
                  _initializeWrapper(
                    builder: (_, __) => _focusingAreaWidget(constraints),
                  ),
                  _contentBuilder(constraints),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

enum _PreviewScaleType { none, width, height }
