import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Lightweight singleton around [BluetoothConnection] for the operator module.
class OperatorBluetoothService {
  OperatorBluetoothService._internal();
  static final OperatorBluetoothService _instance =
      OperatorBluetoothService._internal();

  factory OperatorBluetoothService() => _instance;

  final StreamController<String> _weightController =
      StreamController<String>.broadcast();
  BluetoothConnection? _connection;
  String latestWeight = '--';

  Stream<String> get weightStream => _weightController.stream;

  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Pushes a new weight reading to any listeners.
  void _emitWeight(String weight) {
    latestWeight = weight;
    _weightController.add(weight);
  }

  void updateWeight(String weight) => _emitWeight(weight);

  Future<void> connect() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    if (devices.isEmpty) {
      throw StateError('No bonded Bluetooth devices found');
    }

    final device = devices.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains('HC'),
      orElse: () => devices.first,
    );

    _connection = await BluetoothConnection.toAddress(device.address);

    String buffer = '';
    _connection!.input?.listen((Uint8List data) {
      buffer += utf8.decode(data);
      int idx;
      while ((idx = buffer.indexOf('\n')) != -1) {
        final line = buffer.substring(0, idx).trim();
        buffer = buffer.substring(idx + 1);
        if (line.isNotEmpty) {
          _emitWeight(line);
        }
      }
    }).onDone(() => _connection = null);
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  void dispose() {
    _weightController.close();
    _connection?.dispose();
  }
}
