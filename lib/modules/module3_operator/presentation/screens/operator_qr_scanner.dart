import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:iwms_citizen_app/modules/module3_operator/services/locationservices.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_data_screen.dart';
import 'package:iwms_citizen_app/router/app_router.dart';

class OperatorQRScanner extends StatefulWidget {
  const OperatorQRScanner({super.key});

  @override
  State<OperatorQRScanner> createState() => _OperatorQRScannerState();
}

class _OperatorQRScannerState extends State<OperatorQRScanner> {
  final MobileScannerController _camera = MobileScannerController();

  bool _scanned = false;
  bool _locationReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// ---------------------------------------------------------
  /// 🔥 Ensure location is ready BEFORE scanning
  /// ---------------------------------------------------------
  Future<void> _initLocation() async {
    try {
      await LocationService.refresh();
      setState(() => _locationReady = true);
      print("📍 Location ready: ${LocationService.latitude}, ${LocationService.longitude}");
    } catch (e) {
      print("⚠ Location failed: $e");
      setState(() => _locationReady = false);
    }
  }

  /// ---------------------------------------------------------
  /// 🔥 On QR Detected
  /// ---------------------------------------------------------
  void _handleQR(BarcodeCapture capture) async {
    if (_scanned) return; // prevents double scan

    if (!_locationReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Getting GPS… Please wait")),
      );
      return;
    }

    final raw = capture.barcodes.first.rawValue ?? "";
    if (raw.isEmpty) return;

    setState(() => _scanned = true);
    await _camera.stop();

    final parsed = _parse(raw);
    final customerId = parsed['Customer Id'] ?? 'Unknown';
    final customerName = parsed['Owner Name'] ?? 'Unknown';
    final contactNo = parsed['address'] ?? 'Unknown';

    final lat = LocationService.latitude.toString();
    final lon = LocationService.longitude.toString();

    // ---------------------------------------------------------
    // 🔥 Go to the data screen VIA ROUTER (not Navigator)
    // ---------------------------------------------------------
    if (!mounted) return;

    context.go(
      AppRoutePaths.operatorData,
      extra: {
        'customerId': customerId,
        'customerName': customerName,
        'contactNo': contactNo,
        'latitude': lat,
        'longitude': lon,
      },
    );
  }

  /// ---------------------------------------------------------
  /// 🔍 Parse QR Key:Value Pairs
  /// ---------------------------------------------------------
  Map<String, String> _parse(String data) {
    final out = <String, String>{};

    for (var line in data.split('\n')) {
      final parts = line.split(':');
      if (parts.length == 2) {
        out[parts[0].trim()] = parts[1].trim();
      }
    }
    return out;
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  /// ---------------------------------------------------------
  /// UI
  /// ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (!_locationReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _camera,
            fit: BoxFit.cover,
            onDetect: _handleQR,
          ),

          /// BACK BUTTON
          Positioned(
            top: 40,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.cancel, size: 32, color: Colors.white),
              onPressed: () {
                _camera.stop();
                context.go(AppRoutePaths.operatorHome);
              },
            ),
          ),

          /// FLASH BUTTON
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text("Toggle Flash"),
                onPressed: () => _camera.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
