import 'dart:convert';
import 'dart:typed_data';

import "package:flutter/material.dart";
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
class WeighBridgeReader extends StatefulWidget {
  const WeighBridgeReader({super.key});
  @override
  State<WeighBridgeReader> createState() => _WeighBridgeReaderState();
}

class _WeighBridgeReaderState extends State<WeighBridgeReader> {
  BluetoothConnection? _connection;
  String buffer = "";
  String latestWeight = "";
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _initBT();
  }

  Future<void> _initBT() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    final hc05 = devices.firstWhere(
          (d) => (d.name ?? "").toUpperCase().contains("HC"),
      orElse: () => devices.first,
    );

    try {
      final conn = await BluetoothConnection.toAddress(hc05.address);
      setState(() {
        _connection = conn;
        connected = true;
      });

      conn.input?.listen((Uint8List data) {
        final text = utf8.decode(data);
        buffer += text;
        // split by newline or carriage return
        if (buffer.contains('\n')) {
          final parts = buffer.split('\n');
          for (var line in parts.take(parts.length - 1)) {
            setState(() => latestWeight = line.trim());
            debugPrint("Incoming: $line");
          }
          buffer = parts.last;
        }
      }).onDone(() {
        setState(() => connected = false);
      });
    } catch (e) {
      debugPrint("Connection error: $e");
    }
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weighbridge Live Data")),
      body: Center(
        child: connected
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Live Weight", style: TextStyle(fontSize: 20)),
            Text(latestWeight.isEmpty ? "--" : latestWeight,
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold)),
          ],
        )
            : const Text("Not connected / Waiting...",
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}