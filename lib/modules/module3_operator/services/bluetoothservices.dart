import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_permissons.dart'; 

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final _weightCtrl = StreamController<String>.broadcast();
  Stream<String> get weightStream => _weightCtrl.stream;

  BluetoothConnection? _conn;
  bool get connected => _conn != null && _conn!.isConnected;

  String latestWeight = "--";

  // ✅ Called when a new weight reading arrives
  void updateWeight(String weight) {
    latestWeight = weight;
    _weightCtrl.add(weight); // pushes to StreamBuilder
  }

  Future<void> connect() async {
  // 🔒 Mandatory permission check
  final ok = await BluetoothPermissions.requestAll();
  if (!ok) {
    throw Exception("Bluetooth permissions not granted");
  }

  // 🔄 Prevent plugin crash
  try {
    await FlutterBluetoothSerial.instance.cancelDiscovery();
  } catch (e) {
    print("⚠️ cancelDiscovery skipped: $e");
  }

  final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
  if (devices.isEmpty) {
    throw Exception('No bonded devices found.');
  }

  final dev = devices.firstWhere(
    (d) => (d.name ?? '').toUpperCase().contains('HC'),
    orElse: () => devices.first,
  );

  _conn = await BluetoothConnection.toAddress(dev.address);

  String buffer = '';
  _conn!.input?.listen((Uint8List data) {
    buffer += utf8.decode(data);
    int idx;
    while ((idx = buffer.indexOf('\n')) != -1) {
      final line = buffer.substring(0, idx).trim();
      buffer = buffer.substring(idx + 1);
      if (line.isNotEmpty) updateWeight(line);
    }
  }).onDone(() => _conn = null);
}

  void disconnect() {
    _conn?.dispose();
    _conn = null;
  }

  void dispose() {
    _weightCtrl.close();
  }
}
