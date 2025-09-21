// qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onQRCodeDetected;
  final String title;

  const QRScannerScreen({
    Key? key,
    required this.onQRCodeDetected,
    this.title = 'Scan QR Code',
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  String? result;
  bool flashOn = false;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await controller.toggleTorch();
              setState(() {
                flashOn = !flashOn;
              });
            },
            icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (isProcessing) return;
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String? qrValue = barcodes.first.rawValue;
                      if (qrValue != null) {
                        setState(() {
                          result = qrValue;
                        });
                        widget.onQRCodeDetected(qrValue);
                        // ❌ Jangan pop otomatis, biar user konfirmasi manual
                        isProcessing = true;
                        Future.delayed(const Duration(seconds: 2), () {
                          isProcessing = false;
                        });
                      }
                    }
                  },
                ),
                // Overlay instructions
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Arahkan kamera ke QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: (result != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'QR Code terdeteksi!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data: $result',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(result);
                          },
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: const Text("Gunakan QR Ini"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        )
                      ],
                    )
                  : const Text('Scan QR Code'),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Utility class untuk navigasi scanner
class QRScannerHelper {
  static Future<String?> scanQRCode(
    BuildContext context, {
    String title = 'Scan QR Code',
  }) async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          title: title,
          onQRCodeDetected: (String qrData) {
            // callback tetap dipanggil, tapi tidak auto pop
          },
        ),
      ),
    );
  }
}
