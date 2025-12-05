import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:iwms_citizen_app/core/api_config.dart';
import 'package:iwms_citizen_app/modules/module3_operator/services/locationservices.dart';
import 'package:iwms_citizen_app/router/app_router.dart';

class OperatorQRScanner extends StatefulWidget {
  const OperatorQRScanner({super.key});

  @override
  State<OperatorQRScanner> createState() => _OperatorQRScannerState();
}

class _OperatorQRScannerState extends State<OperatorQRScanner> {
  final MobileScannerController _camera = MobileScannerController();

  bool _scanned = false;
  bool _fetchingCustomer = false;
  String? _customerError;
  Map<String, dynamic>? _currentCustomer;

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
      await LocationService.refresh(timeout: const Duration(seconds: 2));
      print("📍 Location ready: ${LocationService.latitude}, ${LocationService.longitude}");
    } catch (e) {
      print("⚠ Location failed: $e");
    }
  }

  /// ---------------------------------------------------------
  /// 🔥 On QR Detected
  /// ---------------------------------------------------------
  void _handleQR(BarcodeCapture capture) async {
    if (_scanned) return; // prevents double scan

    final raw = capture.barcodes.first.rawValue ?? "";
    if (raw.isEmpty) return;

    setState(() {
      _scanned = true;
      _fetchingCustomer = true;
      _customerError = null;
    });
    await _camera.stop();

    final uid = _extractUid(raw);
    if (uid == null) {
      _showMessage("Invalid QR code");
      _restartScanner();
      return;
    }

    final customer = await _fetchCustomer(uid);
    if (!mounted) return;

    if (customer == null) {
      _showMessage(_customerError ?? "Not a registered user. Please scan again.");
      _restartScanner();
      return;
    }

    setState(() {
      _fetchingCustomer = false;
      _currentCustomer = customer;
    });

    final lat = LocationService.latitude.toString();
    final lon = LocationService.longitude.toString();

    if (!mounted) return;
    await _showCustomerSheet(
      customerId: customer['unique_id'] ?? uid,
      customerName: customer['customer_name'] ?? 'Unknown',
      contactNo: customer['contact_no'] ?? 'Unknown',
      latitude: customer['latitude'] ?? lat,
      longitude: customer['longitude'] ?? lon,
    );
  }

  /// ---------------------------------------------------------
  /// 🔍 Parse QR Key:Value Pairs
  /// ---------------------------------------------------------
  String? _extractUid(String raw) {
    // Preferred: JSON payload { "type": "citizen", "uid": "CUS-..." }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final uid = decoded["uid"] ?? decoded["unique_id"] ?? decoded["id"];
        if (uid is String && uid.trim().isNotEmpty) return uid.trim();
      }
    } catch (_) {
      // fallthrough to legacy parsing
    }

    // Legacy format: plain text or key:value lines
    final lines = raw.split('\n');
    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length == 2) {
        final value = parts[1].trim();
        if (value.isNotEmpty) return value;
      }
    }

    final trimmed = raw.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  Future<Map<String, dynamic>?> _fetchCustomer(String uid) async {
    final uri = Uri.parse("${ApiConfig.mobileBase}waste/customer/")
        .replace(queryParameters: {"unique_id": uid});
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        setState(() => _customerError = "Customer lookup failed (${resp.statusCode})");
        return null;
      }
      final payload = jsonDecode(resp.body);
      if (payload is! Map || payload["status"] != "success") {
        setState(() => _customerError = "Customer not found");
        return null;
      }
      final data = payload["data"];
      if (data is Map<String, dynamic>) {
        return data;
      }
      setState(() => _customerError = "Unexpected response");
      return null;
    } catch (_) {
      setState(() => _customerError = "Unable to reach server");
      return null;
    }
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _showCustomerSheet({
    required String customerId,
    required String customerName,
    required String contactNo,
    required String latitude,
    required String longitude,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm customer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID: $customerId',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                customerName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (contactNo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Contact: $contactNo'),
              ],
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Collect'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.go(
                          AppRoutePaths.operatorData,
                          extra: {
                            'customerId': customerId,
                            'customerName': customerName,
                            'contactNo': contactNo,
                            'latitude': latitude,
                            'longitude': longitude,
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showMessage('Marked as not available');
                        _restartScanner();
                      },
                      child: const Text('Not available'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showMessage('Marked to collect later');
                        _restartScanner();
                      },
                      child: const Text('Collect later'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restartScanner() async {
    setState(() {
      _scanned = false;
      _fetchingCustomer = false;
    });
    try {
      await _camera.start();
    } catch (_) {}
  }

  /// ---------------------------------------------------------
  /// UI
  /// ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
