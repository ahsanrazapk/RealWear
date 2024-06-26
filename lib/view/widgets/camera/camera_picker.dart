import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/base/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'camera_picker_viewer.dart';
import 'circular_progress_bar.dart';
import 'exposure_point_widget.dart';

const Color _lockedColor = Colors.amber;
const Duration _kRouteDuration = Duration(milliseconds: 300);

class CameraPicker extends BaseStateFullWidget {
  CameraPicker(
      {super.key,
      this.enableRecording = true,
      this.maximumRecordingDuration = const Duration(seconds: 15),
      this.resolutionPreset = ResolutionPreset.high,
      required this.question,
      this.recordSingleTap = false});
  final bool enableRecording;
  final Duration maximumRecordingDuration;
  final ResolutionPreset resolutionPreset;
  final String question;
  final bool recordSingleTap;

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
   int _cameraQuarterTurns = 0;
  final bool _enableSetExposure = true;
  final bool _enableExposureControlOnPoint = true;
  final bool _enablePinchToZoom = true;
  final bool _enablePullToZoomInRecord = true;
  final bool _shouldDeletePreviewFile = true;
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

  int get cameraQuarterTurns => _cameraQuarterTurns;


  set cameraQuarterTurns(int value) {
    _cameraQuarterTurns = value;
  }

  bool get enableRecording => widget.enableRecording;

  bool get enableAudio => enableRecording;

  bool get shouldPrepareForVideoRecording => enableRecording && enableAudio && Platform.isIOS;

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
    if (mounted) {
      initCameras();
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
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

  int _previewQuarterTurns(
    DeviceOrientation orientation,
    BoxConstraints constraints,
  ) {
    int turns = 1;
    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        turns = 4;
        break;
      case DeviceOrientation.landscapeRight:
        turns = 3;
        break;
      case DeviceOrientation.portraitDown:
        turns = 2;
        break;
      default:
        turns = 1;
        break;
    }
    cameraQuarterTurns = turns;
    return turns;
  }


  void initCameras([CameraDescription? cameraDescription]) {
    final CameraController? c = _controllerNotifier.value;

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
      await c?.dispose();
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
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.yuv420 : ImageFormatGroup.jpeg,
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
        final dynamic entity = await CameraPickerViewer.pushToViewer(
          context,
          pickerState: this,
          pickerType: CameraPickerViewType.image,
          turns: _cameraQuarterTurns,
          previewXFile: File((await controller!.takePicture()).path),
          shouldDeletePreviewFile: shouldDeletePreviewFile,
        );
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

  void recordDetectionCancel() {
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
    void handleError() {
      _recordCountdownTimer?.cancel();
      isShootingButtonAnimate = false;
      durationNotifier.value = Duration.zero;
      setState(() {});
    }

    if (controller?.value.isRecordingVideo ?? false) {
      controller?.stopVideoRecording().then((XFile xFile) async {
        controller?.setFlashMode(FlashMode.auto);

        final dynamic entity = await CameraPickerViewer.pushToViewer(
          context,
          pickerState: this,
          turns: _cameraQuarterTurns,
          pickerType: CameraPickerViewType.video,
          previewXFile: File(xFile.path),
          shouldDeletePreviewFile: shouldDeletePreviewFile,
        );
      }).catchError((Object e) {
        initCameras();
        handleError();
        throw e;
      }).whenComplete(() {
        isShootingButtonAnimate = false;
        setState(() {});
      });
      return;
    }
    handleError();
  }

  Widget settingsAction(BoxConstraints constraints) {
    return _initializeWrapper(
      builder: (CameraValue v, __) {
        return Container(
          color: (controller?.value.isRecordingVideo ?? false) ? Colors.transparent : Colors.black.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (controller?.value.isRecordingVideo ?? false) && isShootingButtonAnimate
                        ? ValueListenableBuilder<Duration>(
                            valueListenable: durationNotifier,
                            builder: (context, v, w) {
                              return Center(
                                  child: Text(
                                v.toString().substring(2, 7),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ));
                            })
                        : const SizedBox.shrink(),
                    shootingButton(constraints),
                  ],
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get switchCamerasButton {
    return const BackButton();
    /* return CustomIconButton(
      callBack: switchCameras,
      backgroundColor: ColorManager.black.withOpacity(0.4),
      child: SvgManager.getSVG(Assets.iconsFlipCamera, width: 30,height: 30),
    );*/
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
      icon: Icon(icon),
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
    return Container(
      color: controller.value.isRecordingVideo ? Colors.transparent : Colors.black.withOpacity(0.2),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
             /* IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }

  Widget shootingButton(BoxConstraints constraints) {
    const Size outerSize = Size.square(80);
    const Size innerSize = Size.square(80);
    return Semantics(
      label: 'hf_no_number:|hf_commands:record|hf_commands:record video|',
      button: true,
      onTap: () {
        if (enableRecording) {
          recordDetection(constraints);
        }
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerUp: enableRecording
            ? (PointerUpEvent event) {
                // recordDetectionCancel();
              }
            : null,
        onPointerMove: enablePullToZoomInRecord ? (PointerMoveEvent e) => onShootingButtonMove(e, constraints) : null,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(999999)),
          onTap: takePicture,
          onLongPress: enableRecording
              ? () {
                  recordDetection(constraints);
                }
              : null,
          child: SizedBox.fromSize(
            size: outerSize,
            child: Stack(
              children: <Widget>[
                Center(
                  child: AnimatedContainer(
                    duration: kThemeChangeDuration,
                    width: isShootingButtonAnimate ? outerSize.width : innerSize.width,
                    height: isShootingButtonAnimate ? outerSize.height : innerSize.height,
                    padding: EdgeInsets.all(isShootingButtonAnimate ? 20 : 11),
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red,
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
                    ringsWidth: 1.0,
                    ringsColor: ColorManager.primary,
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

      _preview = RotatedBox(
        quarterTurns: _previewQuarterTurns(orientation, constraints),
        child: _preview,
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
    return Builder(builder: (context) {
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
                  _initializeWrapper(
                    builder: (CameraValue value, __) {
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
