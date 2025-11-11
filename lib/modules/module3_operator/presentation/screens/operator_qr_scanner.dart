import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:iwms_citizen_app/modules/module3_operator/services/location_service.dart';
import 'operator_data_screen.dart';

class OperatorQRScanner extends StatefulWidget {
  const OperatorQRScanner({super.key});

  @override
  State<OperatorQRScanner> createState() => _OperatorQRScannerState();
}

class _OperatorQRScannerState extends State<OperatorQRScanner> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _locationReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      await OperatorLocationService.refresh();
      if (mounted) {
        setState(() => _locationReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationReady = false);
      }
    }
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (!_isScanning) return;
    if (!_locationReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fetching location... please wait")),
        );
      }
      return;
    }

    final barcode = capture.barcodes.first.rawValue ?? '';
    if (barcode.isEmpty) return;

    final navigator = Navigator.of(context);
    setState(() => _isScanning = false);
    await _cameraController.stop();
    if (!context.mounted) return;

    final parsed = _parseQrData(barcode);
    final customerId = parsed['Customer Id'] ?? 'Unknown';
    final customerName = parsed['Owner Name'] ?? 'Unknown';
    final contactNo = parsed['address'] ?? 'Unknown';

    final lat = OperatorLocationService.latitude.toString();
    final lon = OperatorLocationService.longitude.toString();

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => OperatorDataScreen(
          customerId: customerId,
          customerName: customerName,
          contactNo: contactNo,
          latitude: lat,
          longitude: lon,
        ),
      ),
    );
  }

  Map<String, String> _parseQrData(String data) {
    final map = <String, String>{};
    for (final line in data.split('\n')) {
      final parts = line.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }
    return map;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleDetection,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _cameraController.stop();
                if (!context.mounted) return;
                navigator.pop();
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text("Toggle Flash"),
                onPressed: () => _cameraController.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
