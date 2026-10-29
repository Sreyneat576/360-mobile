import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Full-screen camera scanner. Pops with the first decoded barcode value.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.title, this.hint});

  final String? title;
  final String? hint;

  /// Opens the scanner and returns the scanned code, or null if dismissed.
  static Future<String?> scan(BuildContext context, {String? title, String? hint}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScannerScreen(title: title, hint: hint),
      ),
    );
  }

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.dataMatrix,
    ],
  );
  bool _done = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final box = size.width * 0.72;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Camera unavailable: ${error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: AppTheme.text(color: Colors.white),
                ),
              ),
            ),
          ),
          // Dim overlay with a clear window.
          Positioned.fill(
            child: CustomPaint(
              painter: _OverlayPainter(windowSize: box),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.title ?? context.t('mobile.scan_product'),
                        style: AppTheme.text(size: 17, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _controller.toggleTorch();
                        setState(() => _torch = !_torch);
                      },
                      icon: Icon(_torch ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => _controller.switchCamera(),
                      icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Text(
                    widget.hint ?? context.t('mobile.scan_hint'),
                    textAlign: TextAlign.center,
                    style: AppTheme.text(size: 14, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.windowSize});
  final double windowSize;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: windowSize,
      height: windowSize * 0.7,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final overlay = Path()..addRect(Offset.zero & size);
    final window = Path()..addRRect(rrect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, window),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.windowSize != windowSize;
}
