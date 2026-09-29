import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  int _currentCameraIndex = 0;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  bool _isCameraLoading = false;
  bool _flashOn = false;
  bool _cameraError = false;

  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _currentZoom = 1.0;

  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestCameraPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed &&
        _cameraPermissionStatus.isGranted) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (!mounted) return;
    setState(() {
      _cameraPermissionStatus = status;
    });

    if (status.isGranted) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraLoading) return;

    setState(() {
      _isCameraLoading = true;
      _cameraError = false;
    });

    try {
      await _cameraController?.dispose();

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No camera found');
      }

      final backIndex = _cameras.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (_currentCameraIndex >= _cameras.length) {
        _currentCameraIndex = 0;
      }

      if (backIndex != -1 && _currentCameraIndex == 0) {
        _currentCameraIndex = backIndex;
      }

      final controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();

      _currentZoom = math.max(1.0, _minZoom);
      if (_currentZoom > _maxZoom) {
        _currentZoom = _maxZoom;
      }

      await controller.setZoomLevel(_currentZoom);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _flashOn = controller.value.flashMode == FlashMode.torch;
        _isCameraLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _isCameraLoading = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (_flashOn) {
        await controller.setFlashMode(FlashMode.off);
      } else {
        await controller.setFlashMode(FlashMode.torch);
      }

      if (!mounted) return;
      setState(() {
        _flashOn = !_flashOn;
      });
    } catch (_) {}
  }

  Future<void> _setZoom(double value) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _currentZoom = value;
    });

    try {
      await controller.setZoomLevel(value);
    } catch (_) {}
  }

  void _showFrontendOnlyMessage(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label UI is ready. Connect it later to your backend flow.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool cameraReady =
        _cameraPermissionStatus.isGranted &&
            _cameraController != null &&
            _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = math.min(constraints.maxWidth * 0.62, 260.0);
          final frameTop = constraints.maxHeight * 0.23;

          return Stack(
            children: [
              Positioned.fill(
                child: cameraReady
                    ? CameraPreview(_cameraController!)
                    : _buildPermissionOrLoadingBackground(),
              ),

              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(cameraReady ? 0.22 : 0.88),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Safe Scan QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _TopCircleButton(
                            icon: _flashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            onTap: cameraReady ? _toggleFlash : null,
                          ),
                          const SizedBox(width: 10),
                          _TopCircleButton(
                            icon: Icons.cameraswitch_rounded,
                            onTap: cameraReady ? _switchCamera : null,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Positioned(
                top: frameTop,
                left: (constraints.maxWidth - frameSize) / 2,
                child: SizedBox(
                  width: frameSize,
                  height: frameSize,
                  child: _ScannerFrame(
                    animation: _scanLineController,
                    showAnimation: cameraReady,
                  ),
                ),
              ),

              Positioned(
                top: frameTop + frameSize + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    cameraReady
                        ? "Let's Scan A QR Code"
                        : 'Allow camera access to start scanning',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              if (!cameraReady)
                Positioned(
                  top: frameTop + frameSize + 60,
                  left: 28,
                  right: 28,
                  child: Column(
                    children: [
                      const Text(
                        'This page is frontend only.\nLater you can connect the scanned QR payload to your backend.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 190,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cameraPermissionStatus.isPermanentlyDenied
                              ? openAppSettings
                              : _requestCameraPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE2B94D),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _cameraPermissionStatus.isPermanentlyDenied
                                ? 'Open Settings'
                                : 'Allow Access',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (cameraReady)
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 118,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 18,
                      ),
                      activeTrackColor: const Color(0xFFE2B94D),
                      inactiveTrackColor: Colors.white38,
                      thumbColor: const Color(0xFFE2B94D),
                      overlayColor: const Color(0x33E2B94D),
                    ),
                    child: Slider(
                      min: _minZoom,
                      max: _maxZoom,
                      value: _currentZoom.clamp(_minZoom, _maxZoom),
                      onChanged: _setZoom,
                    ),
                  ),
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _BottomActionBar(
                  onGalleryTap: () => _showFrontendOnlyMessage('Gallery'),
                  onHistoryTap: () => _showFrontendOnlyMessage('History'),
                  onScanTap: () => _showFrontendOnlyMessage('Scan action'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionOrLoadingBackground() {
    if (_isCameraLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE2B94D),
        ),
      );
    }

    if (_cameraError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Unable to load the camera preview.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white12,
            width: 1.2,
          ),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white70,
          size: 54,
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onScanTap;

  const _BottomActionBar({
    required this.onGalleryTap,
    required this.onHistoryTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFF262629),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomActionItem(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onGalleryTap,
                  ),
                  const SizedBox(width: 88),
                  _BottomActionItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: onHistoryTap,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onScanTap,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7DDC2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF2C2C2F),
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  final Animation<double> animation;
  final bool showAnimation;

  const _ScannerFrame({
    required this.animation,
    required this.showAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(
            painter: _CornerPainter(),
          ),
        ),
        if (showAnimation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0, -0.82 + (animation.value * 1.64)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2B94D),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99E2B94D),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerLength = 32;
    const double strokeWidth = 6;
    const double radius = 16;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // top-left
    canvas.drawLine(
      Offset(radius, strokeWidth / 2),
      Offset(radius + cornerLength, strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(strokeWidth / 2, radius),
      Offset(strokeWidth / 2, radius + cornerLength),
      paint,
    );

    // top-right
    canvas.drawLine(
      Offset(size.width - radius, strokeWidth / 2),
      Offset(size.width - radius - cornerLength, strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - strokeWidth / 2, radius),
      Offset(size.width - strokeWidth / 2, radius + cornerLength),
      paint,
    );

    // bottom-left
    canvas.drawLine(
      Offset(radius, size.height - strokeWidth / 2),
      Offset(radius + cornerLength, size.height - strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(strokeWidth / 2, size.height - radius),
      Offset(strokeWidth / 2, size.height - radius - cornerLength),
      paint,
    );

    // bottom-right
    canvas.drawLine(
      Offset(size.width - radius, size.height - strokeWidth / 2),
      Offset(size.width - radius - cornerLength, size.height - strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - strokeWidth / 2, size.height - radius),
      Offset(size.width - strokeWidth / 2, size.height - radius - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}