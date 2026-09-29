import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'history_page.dart';
import 'verification_result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _scanner = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  late final AnimationController _scanLineController;
  bool _busy = false;
  bool _scannerVisible = true;
  double _zoom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scanner.value.hasCameraPermission || !_scannerVisible) return;
    if (state == AppLifecycleState.resumed) {
      _scanner.start().catchError((Object error) => _showError(error));
    } else if (state == AppLifecycleState.inactive) {
      _scanner.stop().catchError((Object error) => _showError(error));
    }
  }

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String? _payload(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final payload = _payload(capture);
    if (payload != null) await _verify(payload);
  }

  Future<void> _verify(String payload) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ApiService.verifyQr(payload);
      if (!mounted) return;
      setState(() => _scannerVisible = false);
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => VerificationResultPage(payload: payload, result: result)));
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
          title: const Text('Verification unavailable'),
          content: Text('$error\n\nThis QR code has not been verified.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Try again'))]));
    } finally {
      if (mounted) setState(() { _busy = false; _scannerVisible = true; });
    }
  }

  Future<void> _gallery() async {
    if (_busy) return;
    if (kIsWeb) { _showError('Gallery scanning is available on Android and iOS.'); return; }
    setState(() => _busy = true);
    String? payload;
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final capture = await _scanner.analyzeImage(image.path);
        payload = capture == null ? null : _payload(capture);
        if (payload == null) _showError('No QR code found in this image.');
      }
    } catch (error) { _showError(error); }
    finally { if (mounted) setState(() => _busy = false); }
    if (mounted && payload != null) await _verify(payload);
  }

  Future<void> _manualEntry() async {
    if (_busy) return;
    setState(() => _busy = true);
    String value = '';
    final payload = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Verify QR text'),
      content: TextField(maxLines: 5, onChanged: (text) => value = text,
          decoration: const InputDecoration(hintText: 'Paste the QR payload')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
        }, child: const Text('Verify'))],
    ));
    if (!mounted) return;
    setState(() => _busy = false);
    if (payload != null) await _verify(payload);
  }

  Future<void> _history() async {
    if (_busy) return;
    setState(() { _busy = true; _scannerVisible = false; });
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HistoryPage()));
    if (mounted) setState(() { _busy = false; _scannerVisible = true; });
  }

  Future<void> _toggleTorch() async {
    try { await _scanner.toggleTorch(); } catch (error) { _showError(error); }
  }
  Future<void> _switchCamera() async {
    try { await _scanner.switchCamera(); } catch (error) { _showError(error); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: LayoutBuilder(builder: (context, constraints) {
      final frameSize = math.min(constraints.maxWidth * 0.62, 260.0);
      final frameTop = constraints.maxHeight * 0.23;
      return Stack(children: [
        if (_scannerVisible) Positioned.fill(child: MobileScanner(
          controller: _scanner, onDetect: _onDetect,
          errorBuilder: (context, error) => const Center(child: Padding(
            padding: EdgeInsets.all(24), child: Text(
              'Camera unavailable. Allow camera access in settings, or use the centre button to paste QR text.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          )),
        )),
        Positioned.fill(child: IgnorePointer(child: Container(color: Colors.black.withOpacity(0.15)))),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
          const Text('Safe Scan QR', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
          const Spacer(),
          _TopCircleButton(icon: Icons.flash_on_rounded, onTap: _busy ? null : _toggleTorch),
          const SizedBox(width: 10),
          _TopCircleButton(icon: Icons.cameraswitch_rounded, onTap: _busy ? null : _switchCamera),
        ]))),
        Positioned(top: frameTop, left: (constraints.maxWidth - frameSize) / 2,
          child: IgnorePointer(child: SizedBox(width: frameSize, height: frameSize,
            child: _ScannerFrame(animation: _scanLineController, showAnimation: !_busy)))),
        Positioned(top: frameTop + frameSize + 20, left: 20, right: 20,
          child: Text(_busy ? 'Verifying…' : 'Point at a QR code, or tap the centre button to paste text',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16))),
        Positioned(left: 28, right: 28, bottom: 126, child: Slider(
          value: _zoom, activeColor: const Color(0xFFE2B94D), onChanged: _busy ? null : (value) async {
            setState(() => _zoom = value);
            try { await _scanner.setZoomScale(value); } catch (error) { _showError(error); }
          })),
        Positioned(left: 16, right: 16, bottom: 16, child: _BottomActionBar(
          onGalleryTap: _gallery, onHistoryTap: _history, onScanTap: _manualEntry)),
        if (_busy) const Positioned.fill(child: AbsorbPointer(child: ColoredBox(
          color: Color(0x55000000), child: Center(child: CircularProgressIndicator(color: Color(0xFFE2B94D)))))),
      ]);
    }));
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